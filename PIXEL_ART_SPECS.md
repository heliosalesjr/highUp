# Especificações de Pixel Art - High Up

## Dimensões da Tela
- **Viewport**: 360x640 pixels (mobile vertical)
- **Cada sala**: 360x160 pixels

## Dimensões dos Elementos

### Floor (Chão)
- **Espessura total**: 6 pixels
- **Cor de referência**: Marrom terra `Color(0.4, 0.25, 0.15)`
- Cor única para facilitar visualização da espessura

### Paredes Laterais
- **Espessura total**: 6 pixels
- **Composição em camadas**:
  - Base: 6px - Marrom tronco `Color(0.3, 0.2, 0.15)`
  - Highlight (luz): 2px no meio - Marrom claro `Color(0.45, 0.3, 0.2)`

### Salas Split
- **Floor do meio**: mesma espessura de 6 pixels
- **Cor**: mesma cor do floor principal (marrom terra)
- **Largura**:
  - `layout_split` e `layout_split_bird`: largura total da sala (348px, considerando paredes de 6px)
  - `layout_split_01`: plataforma de 120px (1/3 da largura da sala)

## Tema Visual
- **Ambientação**: Floresta/Natureza
- **Paleta de cores**:
  - Marrom terra para os pisos
  - Marrom tronco para paredes laterais (simulando árvores)

## Próximos Passos
1. Criar sprites de pixel art para o floor (6px de altura)
2. Criar sprites de pixel art para as paredes laterais (6px de largura)
3. Adicionar variações e texturas orgânicas (pedras, raízes, folhas, grama)
4. Considerar tiles modulares para variação visual

## Detalhes Técnicos

### Collision do Floor
- **Collision shape**: 1 pixel de altura
- **Posição**: No TOPO do floor visual (linha mais alta)
- **Motivo**: Garante que player e enemies fiquem alinhados na linha superior do piso, não flutuando
- Todos os personagens detectam o topo do piso como "chão"

## Status Atual
- Simulação com cores sólidas implementada
- Todas as salas (normais e split) atualizadas
- Paredes laterais adicionadas em todo o jogo
- Floor e paredes com mesma espessura (6px) para harmonia visual
- Collision do floor ajustada para 1px no topo (personagens alinhados corretamente)
