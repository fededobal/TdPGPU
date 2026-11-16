#include <stdio.h>

//  Sacar por pantalla informaci�n del *device*
// cudaError_t cudaGetDeviceProperties	( struct cudaDeviceProp* prop, int device)	
/*
    struct cudaDeviceProp {
        char name[256];
        size_t totalGlobalMem;
        size_t sharedMemPerBlock;
        int regsPerBlock;
        int warpSize;
        size_t memPitch;
        int maxThreadsPerBlock;
        int maxThreadsDim[3];
        int maxGridSize[3];
        size_t totalConstMem;
        int major;
        int minor;
        int clockRate;
        size_t textureAlignment;
        int deviceOverlap;
        int multiProcessorCount;
        int kernelExecTimeoutEnabled;
        int integrated;
        int canMapHostMemory;
        int computeMode;
        int concurrentKernels;
        int ECCEnabled;
        int pciBusID;
        int pciDeviceID;
        int tccDriver;
    }
*/
void deviceinfo(int device){
  struct cudaDeviceProp capabilities;
  int clockRate;

  cudaGetDeviceProperties (&capabilities, device);
  cudaDeviceGetAttribute(&clockRate, cudaDevAttrClockRate, device);

  printf("\t Name: %s\n", capabilities.name);
  printf("\t Capability (major.minor): %d.%d\n", capabilities.major, capabilities.minor);
  printf("\t totalGlobalMem: %.2f MB\n", capabilities.totalGlobalMem/1024.0f/1024.0f);
  printf("\t sharedMemPerBlock: %.2f KB\n", capabilities.sharedMemPerBlock/1024.0f);
  printf("\t regsPerBlock (32 bits): %d\n", capabilities.regsPerBlock);
  printf("\t warpSize: %d\n", capabilities.warpSize);
  printf("\t memPitch: %.2f KB\n", capabilities.memPitch/1024.0f);
  printf("\t maxThreadsPerBlock: %d\n", capabilities.maxThreadsPerBlock);
  printf("\t maxThreadsDim: %d x %d x %d\n", capabilities.maxThreadsDim[0], capabilities.maxThreadsDim[1], capabilities.maxThreadsDim[2]);
  printf("\t maxGridSize: %d x %d x %d\n", capabilities.maxGridSize[0], capabilities.maxGridSize[1],capabilities.maxGridSize[2]);
  printf("\t totalConstMem: %.2f KB\n", capabilities.totalConstMem/1024.0f);
  printf("\t clockRate: %.2f MHz\n", clockRate/1000.0f);
  printf("\t textureAlignment: %zu\n", capabilities.textureAlignment);
  printf("\t asyncEngineCount: %d\n", capabilities.asyncEngineCount);
  printf("\t multiProcessorCount: %d\n", capabilities.multiProcessorCount);
}

int main(int argc,char* argv[]){
int devices;
int device;

	cudaGetDeviceCount(&devices);
	for(device=0;device<devices;device++){
		printf("---Device %d---\n",device);	
		deviceinfo(device);
		printf("\n");
	}	
	return (0);
}