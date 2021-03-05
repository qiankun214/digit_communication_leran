import sys,os

if len(sys.argv) != 2:
    raise ValueError("ERROR, parameter num is {},need 1".format(len(sys.argv) - 1))
commit_info = sys.argv[1]

with open("./filelist.log",'r') as f:
    file_root = [ x.strip() for x in f.read().strip().split("\n") ]

for root in file_root:
    if not os.path.isdir(root):
        print("INFO:add file {} in git repo".format(root))
        os.system("git add {}".format(root))
        continue
    for name in ("rtl","module_doc","testbench","info"):
        path = os.path.join(root,name)
        if not os.path.exists(path):
            print("WARNING:{} not exists,ignore it".format(path))
            continue
        print("INFO:add dir {} in git repo".format(path))
        os.system("git add {}".format(path))

print(os.system('git commit -m "{}"'.format(commit_info)))
