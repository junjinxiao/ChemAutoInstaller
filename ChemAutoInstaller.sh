echo ChemAutoInstaller
echo Author:Jinzhe Zeng
echo Email:njzjz@qq.com 10154601140@stu.ecnu.edu.cn

CAI_SOFT_DIR=$HOME/ChemAutoInstaller
CAI_PACKAGE_DIR=${CAI_SOFT_DIR}/packages
CAI_BASHRC_FILE=${CAI_SOFT_DIR}/.bashrc

if [ ! -d "${CAI_SOFT_DIR}" ]; then
	mkdir "${CAI_SOFT_DIR}"
fi
if [ ! -d "${CAI_PACKAGE_DIR}" ];then
	mkdir "${CAI_PACKAGE_DIR}"
fi

function setbashrc(){
	if [ ! -f "${CAI_BASHRC_FILE}" ]; then
		touch ${CAI_BASHRC_FILE}
	fi
	source $HOME/.bashrc
	if [ ! -n "${ChemAutoInstaller}" ];then
		echo 'export ChemAutoInstaller=1'>>${CAI_BASHRC_FILE}
		echo 'source '${CAI_BASHRC_FILE}>>$HOME/.bashrc
		source $HOME/.bashrc
	fi
}

function checkNetwork(){
	ping -c 1 114.114.114.114 
	if [ $? -eq 0 ];then
		echo Internet is unblocked.
	else
		#ECNU Internet Login
		echo ChemAutoInstaller needs to connect the Internet.
		CAI_INTERNET_FILE=${CAI_SOFT_DIR}/.internetlogin
		if [ -f "{CAI_INTERNET_FILE}" ];then
			source ${CAI_INTERNET_FILE}
		fi
		if [ ! -n "${ECNUUSERNAME}" ];then
			read -p "Input your ECNU username:" ECNUUSERNAME
			echo 'ECNUUSERNAME='${ECNUUSERNAME}>>${CAI_INTERNET_FILE}
		fi
		if [ ! -n "${ECNUPASSWORD}" ];then
			read -p "Input your ECNU password:" ECNUPASSWORD
			echo 'ECNUPASSWORD='${ECNUPASSWORD}>>${CAI_INTERNET_FILE}
		fi
		curl -d "action=login&username=${ECNUUSERNAME}&password=${ECNUPASSWORD}&ac_id=1&ajax=1" https://login.ecnu.edu.cn/include/auth_action.php
	fi
}

#Anaconda3
function installAnaconda(){
	if ! [ -x "$(command -v anaconda)" ];then
		echo Installing Anaconda 3...
		CAI_ANACONDA_DIR=${CAI_SOFT_DIR}/anaconda3
		wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/archive/Anaconda3-5.2.0-Linux-x86_64.sh -O ${CAI_PACKAGE_DIR}/anaconda3.sh
		bash ${CAI_PACKAGE_DIR}/anaconda3.sh -b -p ${CAI_ANACONDA_DIR}
		echo 'export PATH=$PATH:'${CAI_ANACONDA_DIR}'/bin'>>${CAI_BASHRC_FILE}
	    setbashrc
		setMirror
		echo Anaconda 3 is installed.
	fi
}

function setMirror(){
	wget https://tuna.moe/oh-my-tuna/oh-my-tuna.py -O ${CAI_PACKAGE_DIR}/oh-my-tuna.py
	python ${CAI_PACKAGE_DIR}/oh-my-tuna.py
}

#OpenBabel
function installOpenBabel(){
	echo Installing OpenBabel...
	installAnaconda
	checkNetwork
	conda install -y openbabel -c openbabel
}

#RDkit
function installRDkit(){
	echo Installing RDkit...
	installAnaconda
	checkNetwork
	conda install -y rdkit -c rdkit
}

#ReacNetGenerator
function installReacNetGenerator(){
	echo Installing ReacNetGenerator...
	installAnaconda
	checkNetwork
	conda install -y reacnetgenerator -c njzjz -c openbabel -c rdkit -c omnia
}

#LAMMPS
function installLAMMPS(){
	echo Installing LAMMPS...
	CAI_LAMMPS_DIR=${CAI_SOFT_DIR}/lammps
    wget http://lammps.sandia.gov/tars/lammps-stable.tar.gz -O ${CAI_PACKAGE_DIR}/lammps.tar.gz
	tar -vxf ${CAI_PACKAGE_DIR}/lammps.tar.gz -C ${CAI_PACKAGE_DIR}
	mv ${CAI_PACKAGE_DIR}/lammps-16Mar18 ${CAI_LAMMPS_DIR}	
	cd ${CAI_LAMMPS_DIR}/src && make yes-user-reaxc
	if checkIntel ;then
		cd ${CAI_LAMMPS_DIR}/src && make intel_cpu_intelmpi
	else
		installOpenMPI
		cd ${CAI_LAMMPS_DIR}/src && make mpi
	fi
	echo 'export PATH=$PATH:'${CAI_LAMMPS_DIR}>>${CAI_BASHRC_FILE}
	setbashrc
}

function installOpenMPI(){
	echo Installing OPENMPI...
	if ! [ -x "$(command -v mpirun)" ];then
		CAI_OPENMPI_DIR=${CAI_SOFT_DIR}/openmpi
		checkNetwork	
		wget https://download.open-mpi.org/release/open-mpi/v3.1/openmpi-3.1.0.tar.bz2 -O ${CAI_PACKAGE_DIR}/openmpi.tar.bz2
		tar -vxf ${CAI_PACKAGE_DIR}/openmpi.tar.bz2 -C ${CAI_PACKAGE_DIR}
		mkdir $CAI_OPENMPI_DIR
		installgcc
		installgfortran
		cd ${CAI_PACKAGE_DIR}/openmpi-3.1.0 && ./configure --prefix=${CAI_OPENMPI_DIR}
		cd ${CAI_PACKAGE_DIR}/openmpi-3.1.0/ &&	make all install
        rm -rf ${CAI_PACKAGE_DIR}/openmpi-3.1.0/
		echo 'export PATH=$PATH:'${CAI_OPENMPI_DIR}/bin>>${CAI_BASHRC_FILE}
		echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:'${CAI_OPENMPI_DIR}/lib>>${CAI_BASHRC_FILE}
		setbashrc
	fi
}

function checkIntel(){
	source /share/apps/intel/compilers_and_libraries/linux/bin/compilervars.sh intel64
	if [ -x "$(command -v mpiicpc)" ];then
		return 0
	else
		return 1
	fi
}

function installgcc(){
	if ! [ -x "$(command -v g++)" ];then
		installAnaconda
		conda install -y gcc
	fi
}

function installgfortran(){
	if ! [ -x "$(command -v gfortran)" ];then
		installAnaconda
		conda install -y gfortran_linux-64
	fi
}

#VMD
function installVMD(){
	echo Installing VMD...
	if ! [ -x "$(command -v vmd)" ];then
		CAI_VMD_DIR=${CAI_SOFT_DIR}/vmd
		checkNetwork
		wget http://www.ks.uiuc.edu/Research/vmd/vmd-1.9.3/files/final/vmd-1.9.3.bin.LINUXAMD64-CUDA8-OptiX4-OSPRay111p1.opengl.tar.gz -O ${CAI_PACKAGE_DIR}/vmd.tar.gz
		tar -vxzf ${CAI_PACKAGE_DIR}/vmd.tar.gz -C ${CAI_PACKAGE_DIR}
		cat ${CAI_PACKAGE_DIR}/vmd-1.9.3/configure|sed '16c $install_bin_dir="'${CAI_VMD_DIR}'/bin";'|sed '19c $install_library_dir="'${CAI_VMD_DIR}'/lib/$install_name";'>${CAI_PACKAGE_DIR}/vmd-1.9.3/configure_CAI
		mv ${CAI_PACKAGE_DIR}/vmd-1.9.3/configure_CAI ${CAI_PACKAGE_DIR}/vmd-1.9.3/configure
		chmod +x ${CAI_PACKAGE_DIR}/vmd-1.9.3/configure
		cd ${CAI_PACKAGE_DIR}/vmd-1.9.3/ && ./configure LINUXAMD64
		cd ${CAI_PACKAGE_DIR}/vmd-1.9.3/ && ./configure
		cd ${CAI_PACKAGE_DIR}/vmd-1.9.3/src && make install
		rm -rf ${CAI_PACKAGE_DIR}/vmd-1.9.3/
		echo 'export PATH=$PATH:'${CAI_VMD_DIR}/bin>>${CAI_BASHRC_FILE}
		setbashrc
	fi
}

setbashrc
checkNetwork

ARGS=`getopt -a -o Ah -l all,anaconda,openbabel,rdkit,lammps,vmd,openmpi,reacnetgenerator,help -- "$@"`
#[ $? -ne 0 ] && usage
eval set -- "${ARGS}"

while true;do
	case "$1" in
		--anaconda)
			installAnaconda
			;;
		--openbabel)
			installOpenBabel
			;;
		--rdkit)
			installRDkit
			;;
		--lammps)
			installLAMMPS
			;;
		--vmd)
			installVMD
			;;
		--openmpi)
			installOpenMPI
			;;
		--reacnetgenerator)
			installReacNetGenerator
			;;
		-A|--all)
			installAnaconda
			installOpenBabel
			installRDkit
			installLAMMPS
			installVMD
			installOpenMPI
			installReacNetGenerator
			;;
		-h|--help)
			#usage
			;;
		--)
			break
			;;
		esac
	shift
done
