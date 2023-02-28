# --------------------------------------------------------------------------------------------------------- #
# --- onedirectional_file_synchronization.jl                                                                #                                                                 
# --------------------------------------------------------------------------------------------------------- #
# ---           Python: distutils.file_util.copy_file                                                   --- #
# --------------------------------------------------------------------------------------------------------- #
# --- the package "distutils" is depricated, it should not be used any longer,                              #
# --- the functionality of this package is now included in the package "setuptools", see:                   #
# --- https://docs.python.org/3/distutils/apiref.html                                                       #
# ......................................................................................................... #
# --- setuptools:                                                                                           #
# --- the installation of "setuptools" should not be necessary, but if the package is missing, do:          #
# --- import Conda; Conda.update(); Conda.add("setuptools")                                                 #
# ......................................................................................................... #
# --- manual / dumentation of "distutils.file_util.copy_file":                                              #
# --- https://setuptools.pypa.io/en/latest/deprecated/distutils/apiref.html#distutils.file_util.copy_file   # 
# ---                                                                                                       #
#############################################################################################################

using PyCall
# --- establish PyObjects of the necessary functions "copy_file" & "copy_tree" & "remove_tree":
py_setuptools   = PyCall.pyimport("setuptools")
py_distutils    = py_setuptools.distutils
# py_copy_file = PyCall.pyimport("setuptools.distutils.file_util.copy_file") # is not possible
py_copy_file    = py_distutils.file_util.copy_file
py_copy_tree    = py_distutils.dir_util.copy_tree
py_remove_tree  = py_distutils.dir_util.remove_tree


# --- source and destination file names and folders:
temp_dir        = "/media/stefan/DATA/data/temp"
src_dir         = joinpath(temp_dir,    "src");     mkpath(src_dir)
dst_dir_A       = joinpath(temp_dir,    "dst_A");   mkpath(dst_dir_A)
dst_dir_B       = joinpath(temp_dir,    "dst_B")    
file_a_src      = joinpath(src_dir,     "a.txt")
file_b_src      = joinpath(src_dir,     "b.txt")
file_b_dst_A    = joinpath(dst_dir_A,   "b.txt")

# --- delete 2nd destination folder, if it exist:
@show py_remove_tree(dst_dir_B, verbose=true,   dry_run=true)
try
    @show py_remove_tree(dst_dir_B, verbose=true,  dry_run=false)    
catch
    Base.invokelatest(Base.display_error, Base.catch_stack())
end

# --- write content to source files:
fid = open(file_a_src, "w");    print(fid, "Hello Julia!");   close(fid)
fid = open(file_b_src, "w");    print(fid, "Hello Python!");  close(fid)

# --- copy folder (entire content):
list_of_files = py_copy_tree(src_dir, dst_dir_A, verbose=true); @show list_of_files 

# --- copy folder to non-existing destination folder, it is created automatically:
list_of_files = py_copy_tree(src_dir, dst_dir_B, verbose=true); @show list_of_files 

# --- one-directional synchronization of destination directory-tree (copy only modified files):
# --- 1.) modify one file in destianation directory-tree:
fid = open(file_b_dst_A, "w");    print(fid, "Hello Python! - Where is Julia?");  close(fid)

# --- 2.) copy only new files (keep content of modified file "file_b_dst_A" in dst-folder):
list_of_files = py_copy_tree(src_dir, dst_dir_A, verbose=true, update=true);  @show list_of_files
@show read(file_b_dst_A, String)

# --- copy file only, if source file is new than destination file (one-directional synchronization)
list_of_files = py_copy_file(file_b_src, file_b_dst_A, verbose=true, update=true);  @show list_of_files
@show read(file_b_src,   String)
@show read(file_b_dst_A, String)

