current_target="js";function length(x)return(#x); end function sub(x,from,upto)if is_string(x) then return(string.sub(x,(from+1),upto)); else do upto=(upto or length(x));local i=from;local j=0;local x2={};while (i<upto) do x2[(j+1)]=x[(i+1)];i=(i+1);j=(j+1); end return(x2); end  end  end function push(arr,x)arr[(length(arr)+1)]=x; end function join(a1,a2)do local a3={};local i=0;local len=length(a1);while (i<len) do a3[(i+1)]=a1[(i+1)];i=(i+1); end while (i<(len+length(a2))) do a3[(i+1)]=a2[((i-len)+1)];i=(i+1); end return(a3); end  end function char(str,n)return(string.sub(str,(n+1),(n+1))); end function find(str,pattern,start)do if start then start=(start+1); end local i=string.find(str,pattern,start,true);return((i and (i-1))); end  end function read_file(filename)do local f=io.open(filename);return(f:read("*a")); end  end function write_file(filename,data)do local f=io.open(filename,"w");f:write(data); end  end function exit(code)os.exit(code); end function is_string(x)return((type(x)=="string")); end function is_number(x)return((type(x)=="number")); end function is_boolean(x)return((type(x)=="boolean")); end function is_composite(x)return((type(x)=="table")); end function is_atom(x)return((not is_composite(x))); end function is_table(x)return((is_composite(x) and (x[1]==nil))); end function is_array(x)return((is_composite(x) and (not (x[1]==nil)))); end function parse_number(str)return(tonumber(str)); end function to_string(x)if (x==nil) then return("nil"); elseif is_boolean(x) then return(((x and "true") or "false")); elseif is_atom(x) then return((x.."")); else local str="[";local i=0;while (i<length(x)) do local y=x[(i+1)];str=(str..to_string(y));if (i<(length(x)-1)) then str=(str.." "); end i=(i+1); end return((str.."]")); end  end function eval(x)local f=loadstring(x);return(f()); end current_language="lua";delimiters={};delimiters["("]=true;delimiters[")"]=true;delimiters[";"]=true;delimiters["\n"]=true;whitespace={};whitespace[" "]=true;whitespace["\t"]=true;whitespace["\n"]=true;eof={};function make_stream(str)local s={};s.pos=0;s.string=str;s.length=length(str);return(s); end function peek_char(s)return((((s.pos<s.length) and char(s.string,s.pos)) or eof)); end function read_char(s)local c=peek_char(s);if c then s.pos=(s.pos+1);return(c); end  end function skip_non_code(s)while true do local c=peek_char(s);if (not c) then break; elseif whitespace[c] then read_char(s); elseif (c==";") then while (c and (not (c=="\n"))) do c=read_char(s); end skip_non_code(s); else break; end  end  end function read_atom(s)local str="";while true do local c=peek_char(s);if (c and ((not whitespace[c]) and (not delimiters[c]))) then str=(str..c);read_char(s); else break; end  end local n=parse_number(str);return((((n==nil) and str) or n)); end function read_list(s)read_char(s);local l={};while true do skip_non_code(s);local c=peek_char(s);if (c and (not (c==")"))) then push(l,read(s)); elseif c then read_char(s);break; else error(("Expected ) at "..s.pos)); end  end return(l); end function read_string(s)read_char(s);local str="\"";while true do local c=peek_char(s);if (c and (not (c=="\""))) then if (c=="\\") then str=(str..read_char(s)); end str=(str..read_char(s)); elseif c then read_char(s);break; else error(("Expected \" at "..s.pos)); end  end return((str.."\"")); end function read_quote(s)read_char(s);return({"quote",read(s)}); end function read_unquote(s)read_char(s);return({"unquote",read(s)}); end function read(s)skip_non_code(s);local c=peek_char(s);if (c==eof) then return(c); elseif (c=="(") then return(read_list(s)); elseif (c==")") then error(("Unexpected ) at "..s.pos)); elseif (c=="\"") then return(read_string(s)); elseif (c=="'") then return(read_quote(s)); elseif (c==",") then return(read_unquote(s)); else return(read_atom(s)); end  end operators={};operators["js"]={};operators["js"]["+"]="+";operators["js"]["-"]="-";operators["js"]["*"]="*";operators["js"]["/"]="/";operators["js"]["<"]="<";operators["js"][">"]=">";operators["js"]["="]="==";operators["js"]["<="]="<=";operators["js"][">="]=">=";operators["js"]["and"]="&&";operators["js"]["or"]="||";operators["js"]["cat"]="+";operators["lua"]={};operators["lua"]["+"]="+";operators["lua"]["-"]="-";operators["lua"]["*"]="*";operators["lua"]["/"]="/";operators["lua"]["<"]="<";operators["lua"][">"]=">";operators["lua"]["="]="==";operators["lua"]["<="]="<=";operators["lua"][">="]=">=";operators["lua"]["and"]=" and ";operators["lua"]["or"]=" or ";operators["lua"]["cat"]="..";function get_op(op)return(operators[current_target][op]); end macros={};special={};function is_call(form)return(is_string(form[1])); end function is_operator(form)return((not (get_op(form[1])==nil))); end function is_special(form)return((not (special[form[1]]==nil))); end function is_macro_call(form)return((not (macros[form[1]]==nil))); end function is_macro_definition(form)return((form[1]=="macro")); end function terminator(is_stmt)return(((is_stmt and ";") or "")); end function compile_args(forms)local i=0;local str="(";while (i<length(forms)) do str=(str..compile(forms[(i+1)],false));if (i<(length(forms)-1)) then str=(str..","); end i=(i+1); end return((str..")")); end function compile_body(forms)local i=0;local str=(((current_target=="js") and "{") or "");while (i<length(forms)) do str=(str..compile(forms[(i+1)],true));i=(i+1); end return((((current_target=="js") and (str.."}")) or str)); end function normalize(id)local id2="";local i=0;while (i<length(id)) do local c=char(id,i);if (c=="-") then c="_"; end id2=(id2..c);i=(i+1); end local last=(length(id)-1);if (char(id,last)=="?") then local name=sub(id2,0,last);id2=("is_"..name); end return(id2); end function compile_atom(form,is_stmt)if (form=="[]") then return((((current_target=="lua") and "{}") or "[]")); elseif (form=="nil") then return((((current_target=="js") and "undefined") or "nil")); elseif (is_string(form) and (not (char(form,0)=="\""))) then return((normalize(form)..terminator(is_stmt))); else return(to_string(form)); end  end function compile_call(form,is_stmt)local fn=compile(form[1],false);local args=compile_args(sub(form,1));return((fn..args..terminator(is_stmt))); end function compile_operator(form)local i=1;local str="(";local op=get_op(form[1]);while (i<length(form)) do str=(str..compile(form[(i+1)],false));if (i<(length(form)-1)) then str=(str..op); end i=(i+1); end return((str..")")); end function compile_do(forms,is_stmt)if (not is_stmt) then error("Cannot compile DO as an expression"); end local body=compile_body(forms);return((((current_target=="js") and body) or ("do "..body.." end "))); end function compile_set(form,is_stmt)if (not is_stmt) then error("Cannot compile assignment as an expression"); end if (length(form)<2) then error("Missing right-hand side in assignment"); end local lh=compile(form[1],false);local rh=compile(form[2],false);return((lh.."="..rh..terminator(true))); end function compile_branch(branch,is_first,is_last)local condition=compile(branch[1],false);local body=compile_body(sub(branch,1));local tr="";if (is_last and (current_target=="lua")) then tr=" end "; end if is_first then return((((current_target=="js") and ("if("..condition..")"..body)) or ("if "..condition.." then "..body..tr))); elseif (is_last and (condition=="true")) then return((((current_target=="js") and ("else"..body)) or (" else "..body.." end "))); else return((((current_target=="js") and ("else if("..condition..")"..body)) or (" elseif "..condition.." then "..body..tr))); end  end function compile_if(form,is_stmt)if (not is_stmt) then error("Cannot compile IF as an expression"); end local i=0;local str="";while (i<length(form)) do local is_last=(i==(length(form)-1));local is_first=(i==0);local branch=compile_branch(form[(i+1)],is_first,is_last);str=(str..branch);i=(i+1); end return(str); end function compile_function(form,is_stmt)local name=compile(form[1]);local args=compile_args(form[2]);local body=compile_body(sub(form,2));local tr=(((current_target=="lua") and " end ") or "");return(("function "..name..args..body..tr)); end function compile_get(form,is_stmt)local object=compile(form[1],false);local key=compile(form[2],false);if ((current_target=="lua") and (char(object,0)=="{")) then object=("("..object..")"); end return((object.."["..key.."]"..terminator(is_stmt))); end function compile_dot(form,is_stmt)local object=compile(form[1],false);local key=form[2];return((object.."."..key..terminator(is_stmt))); end function compile_not(form,is_stmt)local expr=compile(form[1],false);local tr=terminator(is_stmt);return((((current_target=="js") and ("!("..expr..")"..tr)) or ("(not "..expr..")"..tr))); end function compile_local(form,is_stmt)if (not is_stmt) then error("Cannot compile local variable declaration as an expression"); end local lh=compile(form[1]);local tr=terminator(true);local keyword=(((current_target=="js") and "var ") or "local ");if (form[2]==nil) then return((keyword..lh..tr)); else local rh=compile(form[2],false);return((keyword..lh.."="..rh..tr)); end  end function compile_while(form,is_stmt)if (not is_stmt) then error("Cannot compile WHILE as an expression"); end local condition=compile(form[1],false);local body=compile_body(sub(form,1));return((((current_target=="js") and ("while("..condition..")"..body)) or ("while "..condition.." do "..body.." end "))); end function compile_list(forms,is_stmt,is_quoted)if is_stmt then error("Cannot compile LIST as a statement"); end local i=0;local str=(((current_target=="lua") and "{") or "[");while (i<length(forms)) do local x=forms[(i+1)];local x1=((is_quoted and quote_form(x)) or compile(x,false));str=(str..x1);if (i<(length(forms)-1)) then str=(str..","); end i=(i+1); end return((str..(((current_target=="lua") and "}") or "]"))); end function compile_to_string(form)if (is_string(form) and (char(form,0)=="\"")) then return(form); elseif is_string(form) then return(("\""..form.."\"")); else return(to_string(form)); end  end function quote_form(form)if is_atom(form) then return(compile_to_string(form)); elseif (form[1]=="unquote") then return(compile(form[2],false)); else return(compile_list(form,false,true)); end  end function compile_quote(forms,is_stmt)if is_stmt then error("Cannot compile quoted form as a statement"); end if (length(forms)<1) then error("Must supply at least one argument to QUOTE"); end return(quote_form(forms[1])); end function compile_macro(form,is_stmt)if (not is_stmt) then error("Cannot compile macro definition as an expression"); end local tmp=current_target;current_target=current_language;eval(compile_function(form,true));local name=form[1];local register={"set",{"get","macros",compile_to_string(name)},name};eval(compile(register,true));current_target=tmp; end special["do"]=compile_do;special["set"]=compile_set;special["get"]=compile_get;special["dot"]=compile_dot;special["not"]=compile_not;special["if"]=compile_if;special["function"]=compile_function;special["local"]=compile_local;special["while"]=compile_while;special["list"]=compile_list;special["quote"]=compile_quote;function compile(form,is_stmt)if (form==nil) then return(""); elseif is_atom(form) then return(compile_atom(form,is_stmt)); elseif is_call(form) then if (is_operator(form) and is_stmt) then error(("Cannot compile operator application as a statement")); elseif is_operator(form) then return(compile_operator(form)); elseif is_macro_definition(form) then compile_macro(sub(form,1),is_stmt);return(""); elseif is_special(form) then local fn=special[form[1]];return(fn(sub(form,1),is_stmt)); elseif is_macro_call(form) then local fn=macros[form[1]];local form=fn(sub(form,1));return(compile(form,is_stmt)); else return(compile_call(form,is_stmt)); end  else error(("Unexpected form: "..to_string(form))); end  end function compile_file(filename)local form;local output="";local s=make_stream(read_file(filename));while true do form=read(s);if (form==eof) then break; end output=(output..compile(form,true)); end return(output); end passed=0;function assert_equal(a,b)local sa=to_string(a);local sb=to_string(b);if (not (sa==sb)) then error((" failed: expected "..sa.." was "..sb)); else passed=(passed+1); end  end function run_tests()print(" running tests...");assert_equal(18,18);assert_equal(123,123);assert_equal(0.123,0.123);assert_equal(17,(16+1));assert_equal(4,(7-3));assert_equal(5,(10/2));assert_equal(6,(2*3));assert_equal(true,(not false));assert_equal(true,(true or false));assert_equal(false,(true and false));assert_equal(17,((true and 17) or 18));assert_equal(18,((false and 17) or 18));assert_equal("foo","foo");assert_equal("\"bar\"","\"bar\"");assert_equal(1,length("\""));assert_equal(2,length("a\""));assert_equal("foobar",("foo".."bar"));assert_equal(2,length(("\"".."\"")));assert_equal("a","a");assert_equal("a","a");assert_equal({},{});assert_equal({1},{1});assert_equal({"a"},{"a"});assert_equal({"a"},{"a"});assert_equal(false,({"a"}=={"a"}));assert_equal(5,length({1,2,3,4,5}));assert_equal(3,length({1,{2,3,4},5}));assert_equal(3,length(({1,{2,3,4},5})[2]));local a="bar";assert_equal({1,2,"bar"},{1,2,a});assert_equal({"a",{2,3,7,"b"}},{"a",{2,3,7,"b"}});print((" "..passed.." passed")); end function usage()print("usage: x [<input> | -t] [-o <output>] [-l <language>]");exit(); end args=arg;if (length(args)<1) then usage(); elseif (args[1]=="-t") then run_tests(); else local input=args[1];local output=false;local i=1;while (i<length(args)) do local arg=args[(i+1)];if ((arg=="-o") or (arg=="-l")) then if (length(args)>(i+1)) then i=(i+1);local arg2=args[(i+1)];if (arg=="-o") then output=arg2; else current_target=arg2; end  else print("missing argument for",arg);usage(); end  else print("unrecognized option:",arg);usage(); end i=(i+1); end if (output==false) then local name=sub(input,0,find(input,"."));output=(name.."."..current_target); end write_file(output,compile_file(input)); end 