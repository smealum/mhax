from datetime import datetime
import sys
import ast

def outputConstantsH(d):
	out=""
	out+=("#ifndef CONSTANTS_H")+"\n"
	out+=("#define CONSTANTS_H")+"\n"
	for k in d:
		out+=("	#define "+k+" "+str(d[k]))+"\n"
	out+=("#endif")+"\n"
	return out

def outputConstantsS(d):
	out=""
	for k in d:
		out+=(k+" equ ("+str(d[k])+")")+"\n"
	return out

def outputConstantsPY(d):
	out=""
	for k in d:
		out+=(k+" = ("+str(d[k])+")")+"\n"
	return out

if len(sys.argv)<1:
	print("use : "+sys.argv[0]+" <extensionless_output_name> <input_file1> <const=value> <input_file2> ...")
	exit()

l = {"BUILDTIME" : "\""+datetime.now().strftime("%Y-%m-%d %H:%M:%S")+"\""}

for a in sys.argv[2:]:
	if "=" in a:
		a = a.split("=")
		l[a[0]] = a[1]
	else:
		s=open(a, "r").read()
		if len(s) > 0:
			l.update(ast.literal_eval(s))

l["FIRM_APPMEMALLOC"] = "(0x07C00000)"

l["MCOPY_CODE_LINEAR_BASE"] = "(0x30000000 + FIRM_SYSTEM_LINEAR_OFFSET - 0x00200000)"
l["MCOPY_GSPHEAP"] = "(0x30000000)"

l["MCOPY_RANDCODEBIN_COPY_BASE"] = "(MCOPY_GSPHEAP + 0x01C00000)"
l["MCOPY_RANDCODEBIN_BASE"] = "(MCOPY_GSPHEAP + FIRM_APPMEMALLOC - MCOPY_CODEBIN_SIZE)"
l["MCOPY_SCANLOOP_CURPTR"] = "(MCOPY_GSPHEAP + 0x000E0000)"
l["MCOPY_SCANLOOP_STRIDE"] = "(0x000001000)"

l["MCOPY_SCANLOOP_TARGETCODE"] = "(0x00120000)"

if "MHAX_VERSION" in l:
	if l["MHAX_VERSION"] == "JPN":
		l["MCOPY_SCANLOOP_MAGICVAL"] = "(0x2A000004)"
	elif l["MHAX_VERSION"] == "USA":
		l["MCOPY_SCANLOOP_MAGICVAL"] = "(0xE1510003)"
	# elif l["MHAX_VERSION"] == "EUR":
	# 	l["MCOPY_SCANLOOP_MAGICVAL"] = "(0x2A000004)"

l["MCOPY_PAYLOAD_BUFFER_PTR"] = "(0x08002c30)" # same JPN/USA
l["MCOPY_CODEBIN_SIZE"] = "(0xE0000)" # same JPN/USA

open(sys.argv[1]+".h","w").write(outputConstantsH(l))
open(sys.argv[1]+".s","w").write(outputConstantsS(l))
open(sys.argv[1]+".py","w").write(outputConstantsPY(l))
