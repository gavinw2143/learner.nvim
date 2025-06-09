vim.opt.runtimepath:append('.')
vim.opt.runtimepath:append('./lua')
package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'
