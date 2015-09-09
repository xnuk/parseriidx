%lex
%%

\s+  return 'WS'
(8|9|10|11|12)(\.1?[0-9])?\b  return 'NUMBER'
"노말"|"노멀"  return 'NORMAL'
"하드"  return 'HARD'
"이중계단"|"겹계단"|"고비용"|"계단"|"연속스크"|"연스크"|"스크발광"|"스크밀집"|"스크"|"폭타"|"동시치기"|"동치"|"축연타"|"축"|"즈레"|"트릴"|"변속"|"초살"|"중살"|"후살"|"데님"|"대칭"|"롱노트"|"롱놋"|"백스핀"  return 'TYPE'
"("  return '('
")"  return ')'
\.\.+  return 'TO'
"또는"  return 'OR'
','  return ','
<<EOF>> return 'EOF'
.  return 'INVALID'

/lex

%{
	/**/
	"use strict"
	const EQ=Symbol(),
		LT=Symbol(),
		GT=Symbol()

	function E(){}
	E.prototype=Object.create(null)

	function Ix(){}
	Ix.prototype=Object.create(E.prototype)

	function Num(str){
		var a=str.split('.')
		this.level=a[0]|0
		this.sublevel=(a[1]==null)?null:(a[1]|0)
	}
	Num.prototype=Object.create(null)
	Num.prototype.toString=function(){
		return `${this.level}.${this.sublevel}`
	}
	Num.prototype.biggerThan=function(num){
		if(this.level>num.level) return true
		if(this.level<num.level) return false
	}

	function NmIx(num1, num2){
		if(num2==null){
			this.min=this.max=num1
			return
		}
		if(compare(num1, num2)===GT){
			this.min=num2
			this.max=num1
		} else{
			this.min=num1
			this.max=num2
		}
	}
	NmIx.prototype=Object.create(Ix.prototype)
	NmIx.prototype.constructor=NmIx
	NmIx.prototype.toString=function(){
		return `NmIx(${this.min}, ${this.max})`
	}

	function HdIx(num1, num2){
		NmIx.call(this, num1, num2)
	}
	HdIx.prototype=Object.create(Ix.prototype)
	HdIx.prototype.constructor=HdIx
	HdIx.prototype.toString=function(){
		return `HdIx(${this.min}, ${this.max})`
	}

	function Type(str){
		this.val=str
		return Type[str]
	}
	Type.prototype=Object.create(E.prototype)
	Type.prototype.constructor=Type
	Type.prototype.toString=function(){return this.val}

	;['폭타','계단','동치','스크','스크밀집','축','축연타','즈레','트릴','변속','초살','중살','후살','데님','대칭','겹계단','롱놋','백스핀'].forEach(v=>{Type[v]=new Type(v)})
	Type['고비용']=Type['이중계단']=Type['겹계단']
	Type['롱노트']=Type['롱놋']
	Type['연스크']=Type['연속스크']=Type['스크발광']=Type['스크밀집']
	Type['동시치기']=Type['동치']

	function And(){
		this.opd=[].concat.apply([], [].slice.call(arguments).map(function(v){return (v instanceof And)?v.opd:v}))
	}
	And.prototype=Object.create(null)
	And.prototype.toString=function(){
		return `And[${this.opd.join(', ')}]`
	}
	function Or(a,b){
		this.opd=[].concat.apply([], [].slice.call(arguments).map(function(v){return (v instanceof Or)?v.opd:v}))
	}
	Or.prototype=Object.create(null)
	Or.prototype.toString=function(){
		return `Or[${this.opd.join(', ')}]`
	}
	function and(a,b){
		if(a===b) return a
		return new And(a,b)
	}
	function or(a,b){
		if(a===b) return a
		return new Or(a,b)
	}

	function compare(a, b){
		if(typeof a==='number' && typeof b==='number' || typeof a==='string' && typeof b==='string'){
			if(a===b) return EQ
			if(a>b) return GT
			return LT
		}
		var result;
		[
			[Num, function(){
				var cmp=compare(a.level, b.level)
				if(cmp===EQ) return compare((a.sublevel|0), (b.sublevel|0))
				return cmp
			}] // 몇 개 더 쓸 수 있을까 싶어서 이래 놓았던 건데....
		].some(v=>{
			if(a instanceof v[0] && b instanceof v[0]){
				result=v[1]()
				return true
			}
			return false
		})
		return result
	}
%}

%left OR
%left WS
%left ','

%start code
%%

code
	: e EOF
		{return $1}
	;

e
	: normalhard
		{$$=$1}
	| TYPE
		{$$=Type($1)}
	| bracket
		{$$=$1}
	| e ',' e
		{$$=or($1, $3)}
	| e WS e
		{$$=and($1, $3)}
	| e WS OR WS e
		{$$=or($1, $5)}
	;

bracket
	: '(' e ')'
		{$$=$2}
	| '(' WS e ')'
		{$$=$3}
	| '(' e WS ')'
		{$$=$2}
	| '(' WS e WS ')'
		{$$=$3}
	;

normalhard
	: NORMAL WS num TO num
		{$$=new NmIx($3, $5)}
	| NORMAL num TO num
		{$$=new NmIx($2, $4)}
	| HARD WS num TO num
		{$$=new HdIx($3, $5)}
	| HARD num TO num
		{$$=new HdIx($2, $4)}
	| num TO num
		{$$=new NmIx($1, $3)}
	| NORMAL WS num
		{$$=new NmIx($3)}
	| NORMAL num
		{$$=new NmIx($2)}
	| HARD WS num
		{$$=new HdIx($3)}
	| HARD num
		{$$=new HdIx($2)}
	| num
		{$$=new NmIx($1)}
	;

num
	: NUMBER
		{$$=new Num(yytext)}
	;

