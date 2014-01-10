# arg1: git dir
# arg2: file to output info to
function gitinfo() 
{
	local dir="$1"
	local f="$2"
	cd "${dir}"
	echo "---------------" >> "${f}"
	basename "${dir}" >> "${f}"
	echo "---------------" >> "${f}"
	echo "Changeset:" >> "${f}"
	git rev-parse HEAD >> "${f}"
	echo "Branch:" >> "${f}"
	git branch | grep "\*.*" >> "${f}"
	echo "Remote Origin:" >> "${f}"
	git remote show origin >> "${f}"
	cd -
}

# arg1: kernel dir
function kernelinfo() 
{
	local dir="$1"
	local f="$2"
	cd "${dir}"
	cp -v .config "${f}"
	cd -
}

# arg1: fex file path
function fexinfo() 
{
	local sf="$1"
	local df="$2"
	cp -v "${sf}" "${df}"
}

# arg1: uenv file path
function uenvinfo() 
{
	local sf="$1"
	local df="$2"
	cp -v "${sf}" "${df}"
}

set -x

OUTPUT_DIR=${OUTPUT_DIR:-"`pwd`/output"}
TMP_DIR=`mktemp -d`
BUILD_SCM_FILE=${BUILD_SCM_FILE:-"${TMP_DIR}/build-scm.txt"}
BUILD_KERNEL_CONFIG_FILE=${BUILD_KERNEL_CONFIG_FILE:-"${TMP_DIR}/kernel.config"}
BUILD_FEX_CONFIG_FILE=${BUILD_FEX_CONFIG_FILE:-"${TMP_DIR}/board.fex"}
BUILD_UENV_CONFIG_FILE=${BUILD_UENV_CONFIG_FILE:-"${TMP_DIR}/uEnv.txt"}

gitinfo "linux-sunxi" "${BUILD_SCM_FILE}"
gitinfo "sunxi-boards" "${BUILD_SCM_FILE}"
gitinfo "sunxi-bsp" "${BUILD_SCM_FILE}"
gitinfo "sunxi-tools" "${BUILD_SCM_FILE}"
gitinfo "u-boot-sunxi" "${BUILD_SCM_FILE}"

kernelinfo "linux-sunxi" "$BUILD_KERNEL_CONFIG_FILE"

fexinfo "${OUTPUT_DIR}/cubietruck.fex" "$BUILD_FEX_CONFIG_FILE"

uenvinfo "${OUTPUT_DIR}/uEnv.txt" "${BUILD_UENV_CONFIG_FILE}" 

#more ${TMP_DIR}/*
