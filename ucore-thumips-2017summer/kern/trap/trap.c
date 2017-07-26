#include <defs.h>
#include <mmu.h>
#include <memlayout.h>
#include <clock.h>
#include <trap.h>
#include <thumips.h>
#include <stdio.h>
#include <assert.h>
#include <console.h>
#include <kdebug.h>
#include <error.h>
#include <syscall.h>
#include <proc.h>
#include <asm/mipsregs.h>
#include <thumips_tlb.h>
#include <pmm.h>
#include <glue_pgmap.h>

#define TICK_NUM 100

#define GET_CAUSE_EXCODE(x)   ( ((x) & CAUSEF_EXCCODE) >> CAUSEB_EXCCODE)

static void print_ticks() {
    cprintf("%d ticks\n",TICK_NUM);
}

static const char *
trapname(int trapno) {
    static const char * const excnames[] = {
        "Interrupt",
        "TLB Modify",
        "TLB miss on load",
        "TLB miss on store",
        "Address error on load",
        "Address error on store",
        "Bus error on instruction fetch",
        "Bus error on data load or store",
        "Syscall",
        "Breakpoint",
        "Reserved (illegal) instruction",
        "Coprocessor unusable",
        "Arithmetic overflow",
    };
    if (trapno < sizeof(excnames)/sizeof(const char * const)) 
      return excnames[trapno];
    else
      return "Unknown";
}

bool
trap_in_kernel(struct trapframe *tf) {
  return !(tf->tf_status & KSU_USER);
}

void
print_trapframe(struct trapframe *tf) {
    cprintf("trapframe at 0x%08x\n", tf);
    print_regs(&tf->tf_regs);
    cprintf(" $ra\t: 0x%08x\n", tf->tf_ra);
    cprintf(" BadVA\t: 0x%08x\n", tf->tf_vaddr);
    cprintf(" Status\t: 0x%08x\n", tf->tf_status);
    cprintf(" Cause\t: 0x%08x\n", tf->tf_cause);
    cprintf(" EPC\t: 0x%08x\n", tf->tf_epc);
    if (!trap_in_kernel(tf)) {
      cprintf("Trap in usermode: ");
    }else{
      cprintf("Trap in kernel: ");
    }
    cprintf(trapname(GET_CAUSE_EXCODE(tf->tf_cause)));
    cputchar('\n');
}

void print_regs(struct pushregs *regs)
{
  int i;
  for (i = 0; i < 30; i++) {
    cprintf(" $%d\t: 0x%08x\n", i+1, regs->reg_r[i]);
  }
}

static void interrupt_handler(struct trapframe *tf)
{
  extern clock_int_handler(void*);
  extern serial_int_handler(void*);
  int i;
  for(i=0;i<8;i++){
    if(tf->tf_cause & (1<<(CAUSEB_IP+i))){
      switch(i){
        case TIMER0_IRQ:
          clock_int_handler(NULL);
          break;
        case COM1_IRQ:
          serial_int_handler(NULL);
          break;
        default:
          print_trapframe(tf);
          panic("Unknown interrupt!");
      }
    }
  }

}

extern pde_t *current_pgdir;



static inline int get_error_code(int write, pte_t *pte)
{
  int r = 0;
  if(pte!=NULL && ptep_present(pte))
    r |= 0x01;
  if(write)
    r |= 0x02;
  return r;
}

static int
pgfault_handler(struct trapframe *tf, uint32_t addr, uint32_t error_code) {
  extern struct mm_struct *check_mm_struct;
  struct mm_struct *mm;
  if (check_mm_struct != NULL) {
    assert(current == idleproc);
    mm = check_mm_struct;
  }
  else {
    if (current == NULL) {
      print_trapframe(tf);
      //print_pgfault(tf);
      panic("unhandled page fault.\n");
    }
    mm = current->mm;
  }
  return do_pgfault(mm, error_code, addr);
}

/* use software emulated mips pgfault */
static void handle_tlbmiss(struct trapframe* tf, int write)
{
  int in_kernel = trap_in_kernel(tf);
  assert(current_pgdir != NULL);
  uint32_t badaddr = tf->tf_vaddr;
  int ret = 0;
  pte_t *pte = get_pte(current_pgdir, tf->tf_vaddr, 0);
  if(pte==NULL || ptep_invalid(pte)){   //PTE miss, pgfault
    ret = pgfault_handler(tf, badaddr, get_error_code(write, pte));
  }else{ //tlb miss only, reload it
    if(!in_kernel){
      if(!ptep_u_read(pte)){
        ret = -1;
        goto exit;
      }
      if(write && !ptep_u_write(pte)){
        ret = -2;
        goto exit;
      }
    }
    tlb_refill(badaddr, pte);
    return ;
  }

exit:
  if(ret){
    print_trapframe(tf);
    if(in_kernel){
      panic("unhandled pgfault");
    }else{
      do_exit(-E_KILLED);
    }
  }
  return ;
}

static void
trap_dispatch(struct trapframe *tf) {
  int code = GET_CAUSE_EXCODE(tf->tf_cause);
  switch(code){
    case EX_IRQ:
      interrupt_handler(tf);
      break;
    case EX_TLBL:
      handle_tlbmiss(tf, 0);
      break;
    case EX_TLBS:
      handle_tlbmiss(tf, 1);
      break;
      /* alignment error or access kernel
       * address space in user mode */
    case EX_ADEL:
    case EX_ADES:
      if(trap_in_kernel(tf)){
        print_trapframe(tf);
        panic("Alignment Error");
      }else{
        print_trapframe(tf);
        panic("Cannot access kernel in user mode");
        do_exit(-E_KILLED);
      }
      break;
    case EX_SYS:
      tf->tf_epc += 4;
      syscall();
      break;
    case EX_RI:
      print_trapframe(tf);
      if(trap_in_kernel(tf)) {
        panic("Do NOT use reserved instruction!");
      }
      do_exit(-E_KILLED);
      break;
    case EX_CPU:
      print_trapframe(tf);
      if(trap_in_kernel(tf)) {
        panic("Cpu exception should not occur in kernel mode!");
      }
      do_exit(-E_KILLED);
      break;
    case EX_OVF:
      print_trapframe(tf);
      if(trap_in_kernel(tf)) {
        panic("Overflow exception occur in kernel mode!");
      }
      do_exit(-E_KILLED);
      break;
    default:
      print_trapframe(tf);
      panic("Unhandled Exception");
  }

}


/* *
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void 
mips_trap(struct trapframe *tf) {
  // dispatch based on what type of trap occurred
  // used for previous projects
  if (current == NULL) {
    trap_dispatch(tf);
  }
  else {
    // keep a trapframe chain in stack
    struct trapframe *otf = current->tf;
    current->tf = tf;

    bool in_kernel = trap_in_kernel(tf);

    trap_dispatch(tf);

    current->tf = otf;
    if (!in_kernel) {
      if (current->flags & PF_EXITING) {
        do_exit(-E_KILLED);
      }
      if (current->need_resched) {
        schedule();
      }
    }
  }
}

