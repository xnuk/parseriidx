var tap=require("tap"),
	readFileSync=require("fs").readFileSync,
	Parser=require("jison").Parser

var parser=new Parser(readFileSync('syntax.jison').toString())

function test(source, expect){
	return tap.equals(parser.parse(source)+'', expect, `${source} => ${expect}`)
}

test('노말 8.4........11.5 하드 8.7', 'And[NmIx(8.4, 11.5), HdIx(8.7, 8.7)]')
test('스크밀집', '스크밀집')
test('노말 8 폭타', 'And[NmIx(8.0, 8.99), 폭타]')
test('노멀 8.7..9.3 하드 8.4..9.3 동치,폭타,스크발광', 'And[NmIx(8.7, 9.3), HdIx(8.4, 9.3), Or[동치, 폭타, 스크밀집]]')
test('노멀 8.7..9.3 하드 8.4..9.3 동치 또는 폭타', 'Or[And[NmIx(8.7, 9.3), HdIx(8.4, 9.3), 동치], 폭타]')
test('노멀 8.7..9.3 하드 8.4..9.3 동치 !폭타', 'And[NmIx(8.7, 9.3), HdIx(8.4, 9.3), 동치, Not(폭타)]')