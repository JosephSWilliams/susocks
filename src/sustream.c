#include <sys/fcntl.h>
#include <poll.h>
int main(){
int TTL = 0;

fcntl(0,4,2050);
fcntl(1,4,2050);
fcntl(3,4,2050);

struct pollfd fds[4];
  fds[0].fd=0       ;
  fds[0].events=3   ;
  fds[0].revents=3  ;

  fds[1].fd=3       ;
  fds[1].events=3   ;
  fds[1].revents=3  ;

  fds[2].fd=1       ;
  fds[2].events=4   ;
  fds[2].revents=4  ;

  fds[3].fd=3       ;
  fds[3].events=4   ;
  fds[3].revents=4  ;

unsigned char buffer[2048]={0};

while (TTL<256){
  if (poll(&fds[0],1,128-(poll(&fds[1],1,0)*128))>0){
    if (poll(&fds[3],1,TTL)>0){
      if (write(3,buffer,read(0,buffer,1024))<1){
        break;
      }
      memset(buffer,0,sizeof(buffer));
      if (TTL>0){
        TTL--;
      }
    }
    else {TTL++;}
  }

  if (poll(&fds[1],1,128-(poll(&fds[0],1,0)*128))>0){
    if (poll(&fds[2],1,TTL)>0){
      if (write(1,buffer,read(3,buffer,1024))<1){
        break;
      }
      memset(buffer,0,sizeof(buffer));
      if (TTL>0){
        TTL--;
      }
    }
    else {TTL++;}
  }
}
exit(0);}
