# Building a Raspberry PI cluster  

>I wanted to have a small development environment that I could use to test out docker swarms and kubernetes in the k3s configuration. This would allow me to stop using Windows Subsystem for Linux (WSL) or VMs to run them, and let me use them for the management of the cluster.  

I looked at several different raspberry pi images, weighted their pros and cons, and then finally settled on using `DietPi`, over a standard minimalist install, or the hypriot image. I felt that DietPi would give me most of the configurability of hypriot, while staying closer to the OOB configuration offered by Raspberry.

---

### Architecture:  
**Hardware**  
| Amount | Description |
| ------ | ----------- |
| 5 | Raspberry pi 3B+ | 
| 1 | switch | 
| 1 | VIXMINI wireless router  |
| 1 | Ankr power supply  |

**Software**  
  - dietpi os  
  - Etcher  
  - Ansible  

---

### Issues & Fixes  
**Issues**  
  * Python apparently wasn't installed on the images that I used - so I made a script to handle that part before running the plays (as part of the playbook)  

```sh
#!/bin/bash
# start_here.sh
# don't forget to "chmod +x start_here.sh"  

USERNAME=root
PASSWORD="XXXXXXXXXXXXXXXXXXX"
HOSTS="n99.ds"
SCRIPT="apt install python -y"

sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no -l ${USERNAME} ${HOSTNAME} "${SCRIPT}"
```

---

### Templates  
**To make things consistent, I templated the config**  
  * Update the following files -  
    * `Automation_Custom_PreScript.sh` with pre-network scripts and place in `/boot`   
    * `Automation_Custom_Script.sh` with post-install scripts and place in `/boot`  
      * any additional packages that I want installed or configurations that I want performed  
    * `dietpi.txt` with desired settings and place in `/boot` - I changed the following -  
      * AUTO_SETUP_LOCALE=en_US.UTF-8  
      * AUTO_SETUP_KEYBOARD_LAYOUT=us  
      * AUTO_SETUP_TIMEZONE=America/New_York  
      * AUTO_SETUP_NET_ETHERNET_ENABLED=1  
      * AUTO_SETUP_NET_WIFI_ENABLED=1  
      * AUTO_SETUP_NET_USESTATIC=1  
      * AUTO_SETUP_NET_STATIC_IP=10.11.0.99  
      * AUTO_SETUP_NET_STATIC_MASK=255.255.255.0  
      * AUTO_SETUP_NET_STATIC_GATEWAY=10.11.0.1  
      * AUTO_SETUP_NET_STATIC_DNS=10.11.0.1 8.8.8.8  
      * AUTO_SETUP_NET_HOSTNAME=n99  
      * AUTO_SETUP_HEADLESS=1  
      * AUTO_SETUP_AUTOMATED=1   
      * AUTO_SETUP_GLOBAL_PASSWORD=XXXXXXX  
      * CONFIG_NTP_MODE=3  
      * CONFIG_WIFI_COUNTRY_CODE=US  
    * `dietpi-wifi.txt` with desired settings and place in `/boot`   
      * aWIFI_SSID[0]='WIFI SSID'  
      * aWIFI_KEY[0]='WIFI PASSWORD'  
  * Enable SSH  
    * put an empty `ssh` file (no extension) in the `/boot` directory  

---

### Playbook Outline  

[![](https://mermaid.ink/img/eyJjb2RlIjoiZ3JhcGggVERcbiAgYTFbW3BpLWNsdXN0ZXJdXSAtLi0-IGEyKGZhOmZhLWNvZGUgMDItc2V0dXAtd29ya2VyKVxuICBhMSAtLi0-IGIxKGZhOmZhLWNvZGUgMDJhLXVwZGF0ZS1tYXN0ZXIpXG4gIGExIC0tPiBiYjFbW2ludmVudG9yeV1dXG4gIGExIC0uLT4gYzEoZmE6ZmEtbG9jayBrZXlzKVxuICBhMSAtLi0-IGQxKGZhOmZhLXB1enpsZS1waWVjZSB2YXJzKVxuICBhMSAtLT4gZTFbW3JvbGVzXV1cbiAgYTEgLS4tPiBpMShmYTpmYS1sb2NrIC5naXRpZ25vcmUpXG4gIGExIC0uLT4gajEoZmE6ZmEtcHV6emxlLXBpZWNlIGFuc2libGUuY2ZnKVxuICBhMSAtLi0-IGsxKGZhOmZhLXRlcm1pbmFsIHN0YXJ0X2hlcmUpXG5cbiAgYmIxIC0uLT4gYmIyKGZhOmZhLXB1enpsZS1waWVjZSBob3N0cylcblxuICBlMSAtLT4gZjFbW3dvcmtlcl1dXG4gIGYxIC0tPiBnMVtbdGFza3NdXVxuICBnMSAtLi0-IGcyKGZhOmZhLWNvZGUgbWFpbilcbiAgZzEgLS4tPiBnMyhmYTpmYS1jb2RlIG5ld19ub2RlKVxuICBnMSAtLi0-IGc0KGZhOmZhLWNvZGUgc2V0X2FjY291bnRzKVxuICBnMSAtLi0-IGc1KGZhOmZhLWNvZGUgc2V0X2NsdXN0ZXJfYXBwcylcbiAgZzEgLS4tPiBnNihmYTpmYS1jb2RlIHNldF9jbHVzdGVyX2NvbmZpZylcbiAgZzEgLS4tPiBnNyhmYTpmYS1jb2RlIHNldF9ob3N0bmFtZSlcbiAgZzEgLS4tPiBnOChmYTpmYS1jb2RlIHNldF9wdWJrZXkpXG4gIGcxIC0uLT4gZzkoZmE6ZmEtY29kZSB2YWxpZGF0ZV9kaWV0cGlfdHh0KVxuIiwibWVybWFpZCI6eyJ0aGVtZSI6ImRhcmsifSwidXBkYXRlRWRpdG9yIjpmYWxzZX0)](https://mermaid-js.github.io/mermaid-live-editor/#/edit/eyJjb2RlIjoiZ3JhcGggVERcbiAgYTFbW3BpLWNsdXN0ZXJdXSAtLi0-IGEyKGZhOmZhLWNvZGUgMDItc2V0dXAtd29ya2VyKVxuICBhMSAtLi0-IGIxKGZhOmZhLWNvZGUgMDJhLXVwZGF0ZS1tYXN0ZXIpXG4gIGExIC0tPiBiYjFbW2ludmVudG9yeV1dXG4gIGExIC0uLT4gYzEoZmE6ZmEtbG9jayBrZXlzKVxuICBhMSAtLi0-IGQxKGZhOmZhLXB1enpsZS1waWVjZSB2YXJzKVxuICBhMSAtLT4gZTFbW3JvbGVzXV1cbiAgYTEgLS4tPiBpMShmYTpmYS1sb2NrIC5naXRpZ25vcmUpXG4gIGExIC0uLT4gajEoZmE6ZmEtcHV6emxlLXBpZWNlIGFuc2libGUuY2ZnKVxuICBhMSAtLi0-IGsxKGZhOmZhLXRlcm1pbmFsIHN0YXJ0X2hlcmUpXG5cbiAgYmIxIC0uLT4gYmIyKGZhOmZhLXB1enpsZS1waWVjZSBob3N0cylcblxuICBlMSAtLT4gZjFbW3dvcmtlcl1dXG4gIGYxIC0tPiBnMVtbdGFza3NdXVxuICBnMSAtLi0-IGcyKGZhOmZhLWNvZGUgbWFpbilcbiAgZzEgLS4tPiBnMyhmYTpmYS1jb2RlIG5ld19ub2RlKVxuICBnMSAtLi0-IGc0KGZhOmZhLWNvZGUgc2V0X2FjY291bnRzKVxuICBnMSAtLi0-IGc1KGZhOmZhLWNvZGUgc2V0X2NsdXN0ZXJfYXBwcylcbiAgZzEgLS4tPiBnNihmYTpmYS1jb2RlIHNldF9jbHVzdGVyX2NvbmZpZylcbiAgZzEgLS4tPiBnNyhmYTpmYS1jb2RlIHNldF9ob3N0bmFtZSlcbiAgZzEgLS4tPiBnOChmYTpmYS1jb2RlIHNldF9wdWJrZXkpXG4gIGcxIC0uLT4gZzkoZmE6ZmEtY29kZSB2YWxpZGF0ZV9kaWV0cGlfdHh0KVxuIiwibWVybWFpZCI6eyJ0aGVtZSI6ImRhcmsifSwidXBkYXRlRWRpdG9yIjpmYWxzZX0)  

---  

#### keys.yml

```yml
JOIN_K3S_CLUSTER     : "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
JOIN_DOCKER_SWARM    : "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

---

### Knowledge:  
**Some of the resources that I used for this**  
  - [Setup DietPi on Raspberry](https://pimylifeup.com/raspberry-pi-dietpi/)  
  - [Cluster computing on the Raspberry Pi with Kubernetes](https://opensource.com/life/16/2/build-a-kubernetes-cloud-with-raspberry-pi)  
  - [Kubernetes Raspberry Pi 3 cluster](https://github.com/Project31/ansible-kubernetes-openshift-pi3)  
  - [SSL certs easy with k3s](https://opensource.com/article/20/3/ssl-letsencrypt-k3s?utm_campaign=intrel)  
  - [Grafana Docker image](https://grafana.com/docs/grafana/latest/installation/docker/)  
  - [BrewPi](https://wiki.brewpi.com/getting-started/raspberry-pi-docker-install)  

---  

|[#dsmith73](https://github.com/dsmith73)|
| :---: |
|![github.com/dsmith73](https://avatars1.githubusercontent.com/u/44279121?s=60&u=7a933a33b51505f9d6435eeffae1c8156a47dc77&v=4 "github.com/dsmith73")  |  
