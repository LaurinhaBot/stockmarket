# 🚫 Erros Corrigidos - Nunca Repetir

## ES Module vs CommonJS Error

**Erro**: `ReferenceError: module is not defined in ES module scope`

**Causa**: Arquivo `.js` com `module.exports` (CommonJS) em ambiente com `"type": "module"` no `package.json`

**Solução Correta**:
1. Se precisa usar CommonJS:
   - Renomear arquivo para `.cjs` (ex: `index.cjs`)
   - OU adicionar `"type": "commonjs"` no `package.json`

2. Se precisa usar ES Module:
   - Usar `export default` e `import`
   - Ex: `export default { start: () => console.log("Started") }`

**Arquivos Corrigidos**:
- ✅ `students-repo/backend/dist/index.js` → Criado com CommonJS (`module.exports`)
- ✅ `students-repo/backend/index.js` → Criado com CommonJS
- ✅ `students-repo/Dockerfile.backend` → Criado com ES Module (`export default`)

**Erro Recorrente**: Sempre verificar o tipo de módulo no `package.json` antes de criar arquivos `.js` com `module.exports` ou `export default`

**Regra de Ouro**:
- Se `package.json` tem `

**Data**: 2026-04-13
**Contexto**: Deploy do teaching-platform-backend e students-repo