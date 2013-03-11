fs=require("fs");var delimiters={};delimiters["("]=true;delimiters[")"]=true;delimiters[";"]=true;delimiters["\n"]=true;var whitespace={};whitespace[" "]=true;whitespace["\t"]=true;whitespace["\n"]=true;var operators={};operators["+"]="+";operators["-"]="-";operators["<"]="<";operators[">"]=">";operators["and"]="&&";operators["or"]="||";operators["cat"]="+";operators["="]="==";var special={};special["do"]=compile_do;special["set"]=compile_set;special["get"]=compile_get;special["dot"]=compile_dot;special["not"]=compile_not;special["if"]=compile_if;special["function"]=compile_function;special["declare"]=compile_declare;special["while"]=compile_while;special["each"]=compile_each;special["list"]=compile_list;special["quote"]=compile_quote;var macros={};var current_target="js";var current_language="lua";function error(msg){throw(msg);}function type(x){return(type(x));}function array_length(arr){return((#arr+1));}function array_sub(arr,start,end){{end=(end||array_length(arr));var i=start;var j=0;var arr2={};while((i<end)){arr2[j]=arr[i];i=(i+1);j=(j+1);}}}function string_length(str){return(string.len(str));}function string_start(){return(1);}function string_end(str){return(string_length(str));}function string_ref(str,n){return(string.sub(str,n,n));}function string_sub(str,start,end){return(string.sub(str,start,end));}function read_file(filename){{var f=io.open(filename);return(f:read("*a"));}}function write_file(filename,data){{var f=io.open(filename,"w");f:write(data);}}function make_stream(str){var s={};s.pos=0;s.string=str;s.len=string_length(str);return(s);}function peek_char(s){if((s.pos<s.len)){return(string_ref(s.string,s.pos));}}function read_char(s){var c=peek_char(s);if(c){s.pos=(s.pos+1);return(c);}}function skip_non_code(s){var c;while(true){c=peek_char(s);if(!(c)){break;}else if(whitespace[c]){read_char(s);}else if((c==";")){while((c&&!((c=="\n")))){c=read_char(s);}skip_non_code(s);}else {break;}}}function read_atom(s){var c;var str="";while(true){c=peek_char(s);if((c&&(!(whitespace[c])&&!(delimiters[c])))){str=(str+c);read_char(s);}else {break;}}var n=parseFloat(str);if(isNaN(n)){return(str);}else {return(n);}}function read_list(s){read_char(s);var c;var l=[];while(true){skip_non_code(s);c=peek_char(s);if((c&&!((c==")")))){l.push(read(s));}else if(c){read_char(s);break;}else {error(("Expected ) at "+s.pos));}}return(l);}function read_string(s){read_char(s);var c;var str="\"";while(true){c=peek_char(s);if((c&&!((c=="\"")))){if((c=="\\")){str=(str+read_char(s));}str=(str+read_char(s));}else if(c){read_char(s);break;}else {error(("Expected \" at "+s.pos));}}return((str+"\""));}function read_quote(s){read_char(s);return(["quote",read(s)]);}function read_unquote(s){read_char(s);return(["unquote",read(s)]);}function read(s){skip_non_code(s);var c=peek_char(s);if((c=="(")){return(read_list(s));}else if((c==")")){error(("Unexpected ) at "+s.pos));}else if((c=="\"")){return(read_string(s));}else if((c=="'")){return(read_quote(s));}else if((c==",")){return(read_unquote(s));}else {return(read_atom(s));}}function is_atom(form){return(((type(form)=="string")||(type(form)=="number")));}function is_list(form){return(Array.isArray(form));}function is_call(form){return((is_list(form)&&(type(form[0])=="string")));}function is_operator(form){return(!((operators[form[0]]==null)));}function is_special(form){return(!((special[form[0]]==null)));}function is_macro_call(form){return(!((macros[form[0]]==null)));}function is_macro_definition(form){return((is_call(form)&&(form[0]=="macro")));}function terminator(is_stmt){if(is_stmt){return(";");}else {return("");}}function compile_args(forms){var i=0;var str="(";while((i<array_length(forms))){str=(str+compile(forms[i],false));if((i<(array_length(forms)-1))){str=(str+",");}i=(i+1);}return((str+")"));}function compile_body(forms){var i=0;var str="{";while((i<array_length(forms))){str=(str+compile(forms[i],true));i=(i+1);}return((str+"}"));}function compile_atom(form,is_stmt){var atom=form;if(((type(form)=="string")&&!((string_ref(form,0)=="\"")))){atom=string_ref(form,0);var i=1;while((i<string_length(form))){var c=string_ref(form,i);if((c=="-")){c="_";}atom=(atom+c);i=(i+1);}var last=(string_length(form)-1);if((string_ref(form,last)=="?")){atom=("is_"+string_sub(atom,0,last));}}return((atom+terminator(is_stmt)));}function compile_call(form,is_stmt){var fn=compile(form[0],false);var args=compile_args(array_sub(form,1));return((fn+args+terminator(is_stmt)));}function compile_operator(form){var i=1;var str="(";var op=operators[form[0]];while((i<array_length(form))){str=(str+compile(form[i],false));if((i<(array_length(form)-1))){str=(str+op);}i=(i+1);}return((str+")"));}function compile_do(forms,is_stmt){if(!(is_stmt)){error("Cannot compile DO as an expression");}return(compile_body(forms));}function compile_set(form,is_stmt){if(!(is_stmt)){error("Cannot compile assignment as an expression");}if((array_length(form)<2)){error("Missing right-hand side in assignment");}var lh=compile(form[0],false);var rh=compile(form[1],false);return((lh+"="+rh+terminator(true)));}function compile_branch(branch,is_last){var condition=compile(branch[0],false);var body=compile_body(array_sub(branch,1));if((is_last&&(condition=="true"))){return(body);}else {return(("if("+condition+")"+body));}}function compile_if(form,is_stmt){if(!(is_stmt)){error("Cannot compile if as an expression");}var i=0;var str="";while((i<array_length(form))){var is_last=(i==(array_length(form)-1));var branch=compile_branch(form[i],is_last);str=(str+branch);if((i<(array_length(form)-1))){str=(str+"else ");}i=(i+1);}return(str);}function compile_function(form,is_stmt){var name=compile(form[0]);var args=compile_args(form[1]);var body=compile_body(array_sub(form,2));return(("function "+name+args+body));}function compile_get(form,is_stmt){var object=compile(form[0],false);var key=compile(form[1],false);return((object+"["+key+"]"+terminator(is_stmt)));}function compile_dot(form,is_stmt){var object=compile(form[0],false);var key=form[1];return((object+"."+key+terminator(is_stmt)));}function compile_not(form,is_stmt){var expr=compile(form[0],false);return(("!("+expr+")"+terminator(is_stmt)));}function compile_declare(form,is_stmt){if(!(is_stmt)){error("Cannot compile declaration as an expression");}var lh=compile(form[0]);var tr=terminator(true);if((type(form[1])=="undefined")){return(("var "+lh+tr));}else {var rh=compile(form[1],false);return(("var "+lh+"="+rh+tr));}}function compile_while(form,is_stmt){if(!(is_stmt)){error("Cannot compile WHILE as an expression");}var condition=compile(form[0],false);var body=compile_body(array_sub(form,1));return(("while("+condition+")"+body));}function compile_each(form,is_stmt){if(!(is_stmt)){error("Cannot compile EACH as an expression");}var key=form[0][0];var value=form[0][1];var object=form[1];var body=array_sub(form,2);body.unshift(["set",value,["get",object,key]]);return(("for("+key+" in "+object+")"+compile_body(body)));}function compile_list(forms,is_stmt,is_quoted){if(is_stmt){error("Cannot compile LIST as a statement");}var i=0;var str="[";while((i<array_length(forms))){var x=forms[i];var x1;if(is_quoted){x1=quote_form(x);}else {x1=compile(x,false);}str=(str+x1);if((i<(array_length(forms)-1))){str=(str+",");}i=(i+1);}return((str+"]"));}function compile_to_string(form){if((type(form)=="string")){return(("\""+form+"\""));}else {return((form+""));}}function quote_form(form){if(((type(form)=="string")&&(string_ref(form,0)=="\""))){return(form);}else if(is_atom(form)){return(compile_to_string(form));}else if((form[0]=="unquote")){return(compile(form[1],false));}else {return(compile_list(form,false,true));}}function compile_quote(forms,is_stmt){if(is_stmt){error("Cannot compile quoted form as a statement");}if((array_length(forms)<1)){error("Must supply at least one argument to QUOTE");}return(quote_form(forms[0]));}function compile_macro(form,is_stmt){if(!(is_stmt)){error("Cannot compile macro definition as an expression");}var tmp=current_target;current_target=current_language;eval(compile_function(form,true));var name=form[0];var register=["set",["get","macros",compile_to_string(name)],name];eval(compile(register,true));current_target=tmp;}function compile(form,is_stmt){if(is_atom(form)){return(compile_atom(form,is_stmt));}else if(is_call(form)){if((is_operator(form)&&is_stmt)){error(("Cannot compile operator application as a statement"));}else if(is_operator(form)){return(compile_operator(form));}else if(is_macro_definition(form)){compile_macro(array_sub(form,1),is_stmt);return("");}else if(is_special(form)){var fn=special[form[0]];return(fn(array_sub(form,1),is_stmt));}else if(is_macro_call(form)){var fn=macros[form[0]];var form=fn(array_sub(form,1));return(compile(form,is_stmt));}else {return(compile_call(form,is_stmt));}}else {error(("Unexpected form: "+form));}}function compile_file(filename){var form;var output="";var s=make_stream(read_file(filename));while(true){form=read(s);if(form){output=(output+compile(form,true));}else {break;}}return(output);}function usage(){console.log("usage: x input [-o output] [-t target]");process.exit();}if((array_length(process.argv)<3)){usage();}var input=process.argv[2];var output=(array_sub(input,0,input.indexOf("."))+".js");var i=3;while((i<array_length(process.argv))){var arg=process.argv[i];if(((arg=="-o")||(arg=="-t"))){if((array_length(process.argv)>(i+1))){i=(i+1);var arg2=process.argv[i];if((arg=="-o")){output=arg2;}else {current_target=arg2;}}else {console.log("missing argument for",arg);usage();}}else {console.log("unrecognized option:",arg);usage();}i=(i+1);}write_file(output,compile_file(input));