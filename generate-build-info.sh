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

BUILD_SCM_FILE=${1:-"`pwd`/build.scm"}

gitinfo "linux-sunxi" "${BUILD_SCM_FILE}"
gitinfo "sunxi-boards" "${BUILD_SCM_FILE}"
gitinfo "sunxi-bsp" "${BUILD_SCM_FILE}"
gitinfo "sunxi-tools" "${BUILD_SCM_FILE}"
gitinfo "u-boot-sunxi" "${BUILD_SCM_FILE}"
