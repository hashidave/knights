## Vault Demo - Knights
This repo implements a small application with a simple orchestrator to demonstrate 
Vault features such as AppRole authentication, static and dynamic secrets, PKI, and RBAC

To use the repo it is necessary to start a dev instance of vault with


Create a root CA certificate in the knights_CA folder using openssh

Then, execute ./config_vault.sh to populate vault.

Finally, execute ./orchestrator.sh to kick off the demo

### Top-Level Folder Structure
knights_CA - serves as a root CA.  


