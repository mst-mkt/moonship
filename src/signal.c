#include <signal.h>
#include <unistd.h>

int moonship_notify_parent(void) {
  return kill(getppid(), SIGUSR1);
}
