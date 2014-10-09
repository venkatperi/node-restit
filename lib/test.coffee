CoffeeScript = require 'coffee-script'

input = process.argv.slice(2)

ast = CoffeeScript.nodes input[0]
#console.log JSON.stringify ast, null, 2
js = ast.compile bare: yes
console.log js

console.log CoffeeScript.eval input[0]

