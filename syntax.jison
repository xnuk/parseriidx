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
		GT=Symbol(),
		Subset=Symbol(),
		Superset=Symbol(),
		Intersect=Symbol()

	function E(){}
	E.prototype=Object.create(null)

	function Ix(a, b){ // Num(sublevel!=null)
		if(a.sublevel==null) throw Error("sublevel should not be null")
		if(b==null){
			this.min=this.max=a
			return
		}
		if(b.sublevel==null) throw Error("sublevel should not be null")
		if(a.biggerThan(b)){
			this.min=b
			this.max=a
		} else{
			this.min=a
			this.max=b
		}
	}
	Ix.prototype=Object.create(E.prototype)
	Ix.prototype.lift=function(){
		return new Ix(this.min, this.max)
	}
	Ix.prototype.toNmIx=function(){
		return new NmIx(this.min, this.max)
	}
	Ix.prototype.toHdIx=function(){
		return new HdIx(this.min, this.max)
	}
	Ix.prototype.relateOf=function(ix){
		if(ix.min<=this.min && ix.max>=this.max) return Subset
		if(ix.min>=this.min && ix.max<=this.max) return Superset
		return 
	}

	function ix(a, b){ // Num or Ix
		function ize(a){ // Num or Ix -> Ix
			if(a instanceof Num){
				if(a.sublevel==null) return new Ix(new Num(a.level, 0), new Num(a.level, 99))
				return new Ix(a, a)
			}
			return a
		}

		a=ize(a)
		if(b==null) return a
		b=ize(b)

		if(a instanceof NmIx && b instanceof HdIx || a instanceof HdIx && b instanceof NmIx) throw Error("the type is different.")
		var min=a.min.biggerThan(b.min)?b.min:a.min
		var max=a.max.biggerThan(b.max)?a.max:b.max
		if(a instanceof NmIx || b instanceof NmIx) return new NmIx(min, max)
		if(a instanceof HdIx || b instanceof HdIx) return new HdIx(min, max)
		return new Ix(min, max)
	}

	function Num(str){
		if(arguments.length>1){
			this.level=arguments[0]
			this.sublevel=arguments[1]
			return
		}
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
		if(this.sublevel>num.sublevel) return true
		return false
	}

	function NmIx(a, b){
		this.min=a
		this.max=b
	}
	NmIx.prototype=Object.create(Ix.prototype)
	NmIx.prototype.constructor=NmIx
	NmIx.prototype.toString=function(){
		return `NmIx(${this.min}, ${this.max})`
	}

	function HdIx(a, b){
		this.min=a
		this.max=b
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
		/*
		var g=new And(a,b)
		var nmix=[], hdix=[], types=[]
		g.opd.forEach(v=>{
			if(v instanceof NmIx) return nmix.push(v)
			if(v instanceof HdIx){
				hdix.forEach((w, i, arr)=>{
					var a=v.relateOf(w)
					if(a===Superset) return;
					if(a===Subset) return arr[i]=v
				})
				hdix.push(v)
			}
			if(v instanceof Type && types.indexOf(v)===-1) return types.push(v)
		})*/
	}
	function or(a,b){
		if(a===b) return a
		return new Or(a,b)
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
		{$$=ix($3, $5).toNmIx()}
	| NORMAL num TO num
		{$$=ix($2, $4).toNmIx()}
	| HARD WS num TO num
		{$$=ix($3, $5).toHdIx()}
	| HARD num TO num
		{$$=ix($2, $4).toHdIx()}
	| num TO num
		{$$=ix($1, $3).toNmIx()}
	| NORMAL WS num
		{$$=ix($3).toNmIx()}
	| NORMAL num
		{$$=ix($2).toNmIx()}
	| HARD WS num
		{$$=ix($3).toHdIx()}
	| HARD num
		{$$=ix($2).toHdIx()}
	| num
		{$$=ix($1).toNmIx()}
	;

num
	: NUMBER
		{$$=new Num(yytext)}
	;

