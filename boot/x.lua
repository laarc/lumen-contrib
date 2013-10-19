macros={};symbol_macros={};function is_vararg(name)return((sub(name,(length(name)-3),length(name))=="...")); end function bind1(list,value)local forms={};local i=0;local _4=list;while (i<length(_4)) do local x=_4[(i+1)];if is_list(x) then forms=join(forms,bind1(x,{"at",value,i})); elseif is_vararg(x) then local v=sub(x,0,(length(x)-3));push(forms,{"local",v,{"sub",value,i}});break; else push(forms,{"local",x,{"at",value,i}}); end i=(i+1); end return(forms); end current_target="lua";function length(x)return(#x); end function sub(x,from,upto)if is_string(x) then return(string.sub(x,(from+1),upto)); else upto=(upto or length(x));local i=from;local j=0;local x2={};while (i<upto) do x2[(j+1)]=x[(i+1)];i=(i+1);j=(j+1); end return(x2); end  end function map(fn,arr)local arr1={};local _8=0;local _7=arr;while (_8<length(_7)) do local x=_7[(_8+1)];push(arr1,fn(x));_8=(_8+1); end return(arr1); end function push(arr,x)return(table.insert(arr,x)); end function pop(arr)return(table.remove(arr)); end function last(arr)return(arr[((length(arr)-1)+1)]); end function join(a1,a2)local a3={};local i=0;local len=length(a1);while (i<len) do a3[(i+1)]=a1[(i+1)];i=(i+1); end while (i<(len+length(a2))) do a3[(i+1)]=a2[((i-len)+1)];i=(i+1); end return(a3); end function char(str,n)return(sub(str,n,(n+1))); end function find(str,pattern,start)if start then start=(start+1); end local i=string.find(str,pattern,start,true);return((i and (i-1))); end function split(str,sep)local strs={};while true do local i=find(str,sep);if (i==nil) then break; else push(strs,sub(str,0,i));str=sub(str,(i+1)); end  end push(strs,str);return(strs); end function read_file(path)local f=io.open(path);return(f:read("*a")); end function write_file(path,data)local f=io.open(path,"w");return(f:write(data)); end function write(x)return(io.write(x)); end function exit(code)return(os.exit(code)); end function is_string(x)return((type(x)=="string")); end function is_string_literal(x)return((is_string(x) and (char(x,0)=="\""))); end function is_number(x)return((type(x)=="number")); end function is_boolean(x)return((type(x)=="boolean")); end function is_composite(x)return((type(x)=="table")); end function is_atom(x)return((not is_composite(x))); end function is_table(x)return((is_composite(x) and (x[1]==nil))); end function is_list(x)return((is_composite(x) and (not (x[1]==nil)))); end function parse_number(str)return(tonumber(str)); end function to_string(x)if (x==nil) then return("nil"); elseif is_boolean(x) then if x then return("true"); else return("false"); end  elseif is_atom(x) then return((x.."")); elseif is_table(x) then return("#<table>"); else local str="(";local i=0;local _9=x;while (i<length(_9)) do local y=_9[(i+1)];str=(str..to_string(y));if (i<(length(x)-1)) then str=(str.." "); end i=(i+1); end return((str..")")); end  end function apply(f,args)return(f(unpack(args))); end id_counter=0;function make_id(prefix)id_counter=(id_counter+1);return(("_"..(prefix or "")..id_counter)); end eval_result=nil;function eval(x)local y=("eval_result="..x);local f=load(y);if f then f();return(eval_result); else local f,e=load(x);if f then return(f()); else return(error((e.." in "..x))); end  end  end delimiters={["("]=true,[")"]=true,[";"]=true,["\n"]=true};whitespace={[" "]=true,["\t"]=true,["\n"]=true};function make_stream(str)return({pos=0,string=str,len=length(str)}); end function peek_char(s)if (s.pos<s.len) then return(char(s.string,s.pos)); end  end function read_char(s)local c=peek_char(s);if c then s.pos=(s.pos+1);return(c); end  end function skip_non_code(s)while true do local c=peek_char(s);if (not c) then break; elseif whitespace[c] then read_char(s); elseif (c==";") then while (c and (not (c=="\n"))) do c=read_char(s); end skip_non_code(s); else break; end  end  end read_table={};eof={};read_table[""]=function (s)local str="";while true do local c=peek_char(s);if (c and ((not whitespace[c]) and (not delimiters[c]))) then str=(str..c);read_char(s); else break; end  end local n=parse_number(str);if (not (n==nil)) then return(n); elseif (str=="true") then return(true); elseif (str=="false") then return(false); else return(str); end  end ;read_table["("]=function (s)read_char(s);local l={};while true do skip_non_code(s);local c=peek_char(s);if (c and (not (c==")"))) then push(l,read(s)); elseif c then read_char(s);break; else error(("Expected ) at "..s.pos)); end  end return(l); end ;read_table[")"]=function (s)return(error(("Unexpected ) at "..s.pos))); end ;read_table["\""]=function (s)read_char(s);local str="\"";while true do local c=peek_char(s);if (c and (not (c=="\""))) then if (c=="\\") then str=(str..read_char(s)); end str=(str..read_char(s)); elseif c then read_char(s);break; else error(("Expected \" at "..s.pos)); end  end return((str.."\"")); end ;read_table["'"]=function (s)read_char(s);return({"quote",read(s)}); end ;read_table["`"]=function (s)read_char(s);return({"quasiquote",read(s)}); end ;read_table[","]=function (s)read_char(s);if (peek_char(s)=="@") then read_char(s);return({"unquote-splicing",read(s)}); else return({"unquote",read(s)}); end  end ;function read(s)skip_non_code(s);local c=peek_char(s);if c then return(((read_table[c] or read_table[""]))(s)); else return(eof); end  end function read_from_string(str)return(read(make_stream(str))); end operators={["common"]={["+"]="+",["-"]="-",["*"]="*",["/"]="/",["<"]="<",[">"]=">",["="]="==",["<="]="<=",[">="]=">="},["js"]={["and"]="&&",["or"]="||",["cat"]="+"},["lua"]={["and"]=" and ",["or"]=" or ",["cat"]=".."}};function get_op(op)return((operators["common"][op] or operators[current_target][op])); end function is_call(type,form)if (not is_list(form)) then return(false); elseif (type=="operator") then return((not (get_op(form[1])==nil))); elseif (type=="special") then return((not (special[form[1]]==nil))); elseif (type=="macro") then return((not (macros[form[1]]==nil))); else return(false); end  end function is_symbol_macro(form)return((not (symbol_macros[form]==nil))); end function compile_args(forms,is_compile)local str="(";local i=0;local _11=forms;while (i<length(_11)) do local x=_11[(i+1)];local x1=(function ()if is_compile then return(compile(x)); else return(identifier(x)); end  end )();str=(str..x1);if (i<(length(forms)-1)) then str=(str..","); end i=(i+1); end return((str..")")); end function compile_body(forms,is_tail)local str="";local i=0;local _12=forms;while (i<length(_12)) do local x=_12[(i+1)];local is_t=(is_tail and (i==(length(forms)-1)));str=(str..compile(x,true,is_t));i=(i+1); end return(str); end function identifier(id)local id2="";local i=0;while (i<length(id)) do local c=char(id,i);if (c=="-") then c="_"; end id2=(id2..c);i=(i+1); end local last=(length(id)-1);if (char(id,last)=="?") then local name=sub(id2,0,last);id2=("is_"..name); end return(id2); end function compile_atom(form)if (form=="nil") then if (current_target=="js") then return("undefined"); else return("nil"); end  elseif (is_string(form) and (not is_string_literal(form))) then return(identifier(form)); else return(to_string(form)); end  end function compile_call(form)if (length(form)==0) then return(compile_list(form)); else local fn=form[1];local fn1=compile(fn);local args=compile_args(sub(form,1),true);if is_list(fn) then return(("("..fn1..")"..args)); elseif is_string(fn) then return((fn1..args)); else return(error("Invalid function call")); end  end  end function compile_operator(_13)local op=_13[1];local args=sub(_13,1);local str="(";local op1=get_op(op);local i=0;local _14=args;while (i<length(_14)) do local arg=_14[(i+1)];if ((op1=="-") and (length(args)==1)) then str=(str..op1..compile(arg)); else str=(str..compile(arg));if (i<(length(args)-1)) then str=(str..op1); end  end i=(i+1); end return((str..")")); end function compile_do(forms,is_tail)return(compile_body(forms,is_tail)); end function compile_set(form)if (length(form)<2) then error("Missing right-hand side in assignment"); end local lh=compile(form[1]);local rh=compile(form[2]);return((lh.."="..rh)); end function compile_branch(condition,body,is_first,is_last,is_tail)local cond1=compile(condition);local body1=compile(body,true,is_tail);local tr=(function ()if (is_last and (current_target=="lua")) then return(" end "); else return(""); end  end )();if (is_first and (current_target=="js")) then return(("if("..cond1.."){"..body1.."}")); elseif is_first then return(("if "..cond1.." then "..body1..tr)); elseif ((condition==nil) and (current_target=="js")) then return(("else{"..body1.."}")); elseif (condition==nil) then return((" else "..body1.." end ")); elseif (current_target=="js") then return(("else if("..cond1.."){"..body1.."}")); else return((" elseif "..cond1.." then "..body1..tr)); end  end function compile_if(form,is_tail)local str="";local i=0;local _15=form;while (i<length(_15)) do local condition=_15[(i+1)];local is_last=(i>=(length(form)-2));local is_else=(i==(length(form)-1));local is_first=(i==0);local body=form[((i+1)+1)];if is_else then body=condition;condition=nil; end i=(i+1);str=(str..compile_branch(condition,body,is_first,is_last,is_tail));i=(i+1); end return(str); end function bind_arguments(args,body)local args1={};local _17=0;local _16=args;while (_17<length(_16)) do local arg=_16[(_17+1)];if is_vararg(arg) then local v=sub(arg,0,(length(arg)-3));local expr=(function ()if (current_target=="js") then return({"Array.prototype.slice.call","arguments",length(args1)}); else push(args1,"...");return({"list","..."}); end  end )();body=join({{"local",v,expr},},join(body,{}));break; elseif is_list(arg) then local v=make_id();push(args1,v);body=join({{"bind",arg,v},},join(body,{})); else push(args1,arg); end _17=(_17+1); end return({args1,body}); end function compile_defun(_18)local name=_18[1];local args=_18[2];local body=sub(_18,2);local id=identifier(name);return(compile_function(args,body,id)); end function compile_lambda(_19)local args=_19[1];local body=sub(_19,1);return(compile_function(args,body)); end function compile_function(args,body,name)name=(name or "");local expanded=bind_arguments(args,body);local args1=compile_args(expanded[1]);local body1=compile_body(expanded[2],true);if (current_target=="js") then return(("function "..name..args1.."{"..body1.."}")); else return(("function "..name..args1..body1.." end ")); end  end function compile_get(_20)local object=_20[1];local key=_20[2];local o=compile(object);local k=compile(key);if ((current_target=="lua") and (char(o,0)=="{")) then o=("("..o..")"); end return((o.."["..k.."]")); end function compile_dot(_21)local object=_21[1];local key=_21[2];local o=compile(object);local id=identifier(key);return((o.."."..id)); end function compile_not(_22)local expr=_22[1];local e=compile(expr);local open=(function ()if (current_target=="js") then return("!("); else return("(not "); end  end )();return((open..e..")")); end function compile_return(form)return(compile_call(join({"return",},join(form,{})))); end function compile_local(_23)local name=_23[1];local value=_23[2];local id=identifier(name);local keyword=(function ()if (current_target=="js") then return("var "); else return("local "); end  end )();if (value==nil) then return((keyword..id)); else local v=compile(value);return((keyword..id.."="..v)); end  end function compile_while(form)local condition=compile(form[1]);local body=compile_body(sub(form,1));if (current_target=="js") then return(("while("..condition.."){"..body.."}")); else return(("while "..condition.." do "..body.." end ")); end  end function compile_list(forms,depth)local open=(function ()if (current_target=="lua") then return("{"); else return("["); end  end )();local close=(function ()if (current_target=="lua") then return("}"); else return("]"); end  end )();local str="";local i=0;local _24=forms;while (i<length(_24)) do local x=_24[(i+1)];if (is_list(x) and is_can_unquote(depth) and (x[1]=="unquote-splicing")) then local x1=compile(x[2]);local x2=compile_list(sub(forms,(i+1)),depth);open=("join("..open);close=(close..",join("..x1..","..x2.."))");break; end local x1=(function ()if is_quoting(depth) then return(quote_form(x,depth)); else return(compile(x)); end  end )();str=(str..x1);if (i<(length(forms)-1)) then str=(str..","); end i=(i+1); end return((open..str..close)); end function compile_table(forms)local sep=(function ()if (current_target=="lua") then return("="); else return(":"); end  end )();local str="{";local i=0;while (i<(length(forms)-1)) do local k=compile(forms[(i+1)]);local v=compile(forms[((i+1)+1)]);if ((current_target=="lua") and is_string_literal(k)) then k=("["..k.."]"); end str=(str..k..sep..v);if (i<(length(forms)-2)) then str=(str..","); end i=(i+2); end return((str.."}")); end function compile_each(_25)local t=_25[1][1];local k=_25[1][2];local v=_25[1][3];local body=sub(_25,1);local t1=compile(t);if (current_target=="lua") then local body1=compile_body(body);return(("for "..k..","..v.." in pairs("..t1..") do "..body1.." end")); else local body1=compile_body(join({{"set",v,{"get",t,k}},},join(body,{})));return(("for("..k.." in "..t1.."){"..body1.."}")); end  end function is_quoting(depth)return(is_number(depth)); end function is_quasiquoting(depth)return((is_quoting(depth) and (depth>0))); end function is_can_unquote(depth)return((is_quoting(depth) and (depth==1))); end function quote_form(form,depth)if is_atom(form) then if is_string_literal(form) then local str=sub(form,1,(length(form)-1));return(("\"\\\""..str.."\\\"\"")); elseif is_string(form) then return(("\""..form.."\"")); else return(to_string(form)); end  elseif (is_can_unquote(depth) and (form[1]=="unquote")) then return(compile(form[2])); elseif (is_quasiquoting(depth) and (not is_can_unquote(depth)) and ((form[1]=="unquote") or (form[1]=="unquote-splicing"))) then return(compile_list(form,(depth-1))); elseif (is_quasiquoting(depth) and (form[1]=="quasiquote")) then return(compile_list(form,(depth+1))); else return(compile_list(form,depth)); end  end function compile_quote(_26)local form=_26[1];return(quote_form(form,0)); end function compile_quasiquote(_27)local form=_27[1];return(quote_form(form,1)); end function compile_defmacro(_28)local name=_28[1];local args=_28[2];local body=sub(_28,2);local lambda=join({"lambda",args,},join(body,{}));local register={"set",{"get","macros",{"quote",name}},lambda};eval(compile_for_target("lua",register,true));return(""); end function compile_macrolet(_29,is_tail)local macros=_29[1];local body=sub(_29,1);local _31=0;local _30=macros;while (_31<length(_30)) do local macro=_30[(_31+1)];compile_defmacro(macro);_31=(_31+1); end local body1=compile(join({"do",},join(body,{})),nil,is_tail);local _33=0;local _32=macros;while (_33<length(_32)) do local macro=_32[(_33+1)];macros[macro[1]]=nil;_33=(_33+1); end return(body1); end function compile_symbol_macrolet(_34,is_tail)local expansions=_34[1];local body=sub(_34,1);local _36=0;local _35=expansions;while (_36<length(_35)) do local expansion=_35[(_36+1)];symbol_macros[expansion[1]]=expansion[2];_36=(_36+1); end local body1=compile(join({"do",},join(body,{})),nil,is_tail);local _38=0;local _37=expansions;while (_38<length(_37)) do local expansion=_37[(_38+1)];symbol_macros[expansion[1]]=nil;_38=(_38+1); end return(body1); end function compile_special(form,is_stmt,is_tail)local name=form[1];local sp=special[name];if ((not is_stmt) and sp["stmt?"]) then return(compile({{"lambda",{},form}},false,is_tail)); else local is_tr=(is_stmt and (not sp["self-tr"]));local tr=(function ()if is_tr then return(";"); else return(""); end  end )();local fn=sp["compiler"];return((fn(sub(form,1),is_tail)..tr)); end  end special={["do"]={["compiler"]=compile_do,["self-tr"]=true,["stmt?"]=true},["if"]={["compiler"]=compile_if,["self-tr"]=true,["stmt?"]=true},["while"]={["compiler"]=compile_while,["self-tr"]=true,["stmt?"]=true},["defun"]={["compiler"]=compile_defun,["self-tr"]=true,["stmt?"]=true},["defmacro"]={["compiler"]=compile_defmacro,["self-tr"]=true,["stmt?"]=true},["macrolet"]={["compiler"]=compile_macrolet,["self-tr"]=true},["symbol-macrolet"]={["compiler"]=compile_symbol_macrolet,["self-tr"]=true},["return"]={["compiler"]=compile_return,["stmt?"]=true},["local"]={["compiler"]=compile_local,["stmt?"]=true},["set"]={["compiler"]=compile_set,["stmt?"]=true},["each"]={["compiler"]=compile_each,["stmt?"]=true},["get"]={["compiler"]=compile_get},["dot"]={["compiler"]=compile_dot},["not"]={["compiler"]=compile_not},["list"]={["compiler"]=compile_list},["table"]={["compiler"]=compile_table},["quote"]={["compiler"]=compile_quote},["quasiquote"]={["compiler"]=compile_quasiquote},["lambda"]={["compiler"]=compile_lambda}};function is_can_return(form)if is_call("macro",form) then return(false); elseif is_call("special",form) then return((not special[form[1]]["stmt?"])); else return(true); end  end function compile(form,is_stmt,is_tail)local tr=(function ()if is_stmt then return(";"); else return(""); end  end )();if (is_tail and is_can_return(form)) then form={"return",form}; end if (form==nil) then return(""); elseif is_symbol_macro(form) then return(compile(symbol_macros[form],is_stmt,is_tail)); elseif is_atom(form) then return((compile_atom(form)..tr)); elseif is_call("operator",form) then return((compile_operator(form)..tr)); elseif is_call("special",form) then return(compile_special(form,is_stmt,is_tail)); elseif is_call("macro",form) then local fn=macros[form[1]];local form=apply(fn,sub(form,1));return(compile(form,is_stmt,is_tail)); else return((compile_call(form)..tr)); end  end function compile_file(file)local form;local output="";local s=make_stream(read_file(file));while true do form=read(s);if (form==eof) then break; end output=(output..compile(form,true)); end return(output); end function compile_files(files)local output="";local _40=0;local _39=files;while (_40<length(_39)) do local file=_39[(_40+1)];output=(output..compile_file(file));_40=(_40+1); end return(output); end function compile_for_target(target,...)local args={...};local previous_target=current_target;current_target=target;local result=apply(compile,args);current_target=previous_target;return(result); end function rep(str)return(print(to_string(eval(compile(read_from_string(str)))))); end function repl()local execute=function (str)rep(str);return(write("> ")); end ;write("> ");while true do local str=io.stdin:read();if str then execute(str); else break; end  end  end args=arg;standard={"boot.x","lib.x","reader.x","compiler.x"};function usage()print("usage: x [<inputs>] [-o <output>] [-t <target>] [-e <expr>]");return(exit()); end dir=args[1];if ((args[2]=="-h") or (args[2]=="--help")) then usage(); end local inputs={};local output=nil;local target=nil;local expr=nil;local i=1;local _41=args;while (i<length(_41)) do local arg=_41[(i+1)];if ((arg=="-o") or (arg=="-t") or (arg=="-e")) then if (i==(length(args)-1)) then print("missing argument for",arg); else i=(i+1);local arg2=args[(i+1)];if (arg=="-o") then output=arg2; elseif (arg=="-t") then target=arg2; elseif (arg=="-e") then expr=arg2; end  end  elseif ("-"==sub(arg,0,1)) then print("unrecognized option:",arg);usage(); else push(inputs,arg); end i=(i+1); end if output then if target then current_target=target; end write_file(output,compile_files(inputs)); else local _43=0;local _42=standard;while (_43<length(_42)) do local file=_42[(_43+1)];eval(compile_file((dir.."/"..file)));_43=(_43+1); end local _45=0;local _44=inputs;while (_45<length(_44)) do local file=_44[(_45+1)];eval(compile_file(file));_45=(_45+1); end if expr then rep(expr); else repl(); end  end 