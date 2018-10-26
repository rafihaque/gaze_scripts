function outJ = readJson_builtIn(path2Json)
	txtID=fopen(path2Json,'r');
	txt=textscan(txtID,'%c');
	outJ=jsondecode(txt{1,1})
end
