# Especificações de Pixel Art - High Up

## Dimensões da Tela
- **Viewport**: 360x640 pixels (mobile vertical)
- **Cada sala**: 360x160 pixels

## Parallax Background (4 Camadas)

| Camada | Nome | Dimensões | Velocidade | Repetição |
|--------|------|-----------|------------|-----------|
| **1** | Sky (Céu) | 360×1280px | 0.1x | 1280px |
| **2** | Far Trees (Distante) | 360×640px | 0.3x | 640px |
| **3** | Mid Trees (Médio) | 360×480px | 0.6x | 480px |
| **4** | Close Leaves (Frente) | 360×240px | 0.85x | 240px |

**IMPORTANTE**: Todas as texturas devem ser **tileables verticalmente** (o topo deve conectar perfeitamente com a base).

Para detalhes completos sobre o sistema de parallax, cores sugeridas e como criar texturas tileables, veja **[PARALLAX_GUIDE.md](PARALLAX_GUIDE.md)**.

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

## Dimensões Ideais para Sprites/Tiles

| Elemento | Tamanho Tile | Repetição | Total Final |
|----------|--------------|-----------|-------------|
| **Piso** | 16×6px ou 32×6px | Horizontal | 360×6px |
| **Paredes** | 6×16px ou 6×32px | Vertical | 6×160px |

**Recomendação**: Usar tiles pequenos e repetíveis em vez de sprites únicas da largura/altura total
- Arquivos menores
- Fácil criar variações
- Melhor para padrões e texturas

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

## Como Adicionar/Modificar Tiles

### Adicionar Novos Tiles de Piso

1. **Criar as sprites**:
   - Dimensão: 16×6px
   - Salvar em: `assets/aseprite-floor/`
   - Nomenclatura: `piso5.png`, `piso6.png`, etc.

2. **Atualizar os arquivos de código** (adicione os novos preloads no array `floor_tiles`):
   - `scripts/room.gd` (piso principal das salas)
   - `scenes/room_layouts/layout_split.gd` (piso do meio - salas split)
   - `scenes/room_layouts/layout_split_01.gd` (plataforma do meio - menor)
   - `scenes/room_layouts/layout_split_bird.gd` (piso do meio - com birds)

3. **Exemplo de modificação**:
   ```gdscript
   var floor_tiles = [
       preload("res://assets/aseprite-floor/piso1.png"),
       preload("res://assets/aseprite-floor/piso2.png"),
       preload("res://assets/aseprite-floor/piso3.png"),
       preload("res://assets/aseprite-floor/piso4.png"),
       preload("res://assets/aseprite-floor/piso5.png"),  # <- ADICIONE AQUI
       preload("res://assets/aseprite-floor/piso6.png"),  # <- E AQUI
   ]
   ```

### Adicionar Novos Tiles de Parede

1. **Criar as sprites**:
   - Dimensão: 6×32px
   - Salvar em: `assets/aseprite-walls/`
   - Nomenclatura: `wall5.png`, `wall6.png`, etc.

2. **Atualizar o arquivo de código** (adicione os novos preloads no array `wall_tiles`):
   - `scripts/room.gd` (paredes laterais de todas as salas)

3. **Exemplo de modificação**:
   ```gdscript
   var wall_tiles = [
       preload("res://assets/aseprite-walls/wall1.png"),
       preload("res://assets/aseprite-walls/wall2.png"),
       preload("res://assets/aseprite-walls/wall3.png"),
       preload("res://assets/aseprite-walls/wall4.png"),
       preload("res://assets/aseprite-walls/wall5.png"),  # <- ADICIONE AQUI
       preload("res://assets/aseprite-walls/wall6.png"),  # <- E AQUI
   ]
   ```

### Modificar Lógica de Criação dos Pisos

**Arquivo principal**: `scripts/room.gd`
- **Função**: `create_floor()` (linha ~44)
- **Responsável por**: Criar o piso principal de todas as salas

**Arquivos de salas split**:
- `scenes/room_layouts/layout_split.gd` - função `create_middle_floor()`
- `scenes/room_layouts/layout_split_01.gd` - função `create_middle_platform()`
- `scenes/room_layouts/layout_split_bird.gd` - função `create_middle_floor()`

**Constantes importantes**:
- `FLOOR_TILE_WIDTH = 16` - Largura de cada tile do piso
- `FLOOR_THICKNESS = 6` - Altura do piso

### Modificar Lógica de Criação das Paredes

**Arquivo principal**: `scripts/room.gd`
- **Função**: `create_walls()` (linha ~74)
- **Responsável por**: Criar as paredes laterais de todas as salas

**Constantes importantes**:
- `WALL_TILE_HEIGHT = 32` - Altura de cada tile da parede
- `WALL_THICKNESS = 6` - Largura das paredes

**Exemplos de modificações**:
- Alterar tamanho dos tiles: modificar `FLOOR_TILE_WIDTH` ou `WALL_TILE_HEIGHT`
- Mudar lógica de seleção: trocar `randi() % tiles.size()` por outro algoritmo
- Adicionar padrões específicos: criar lógica condicional na escolha dos tiles

## Status Atual
- Sistema de tiles aleatórios implementado para **pisos** (4 variações: piso1-4)
  - Tiles de 16×6px com seleção aleatória
  - Todas as salas (normais e split) usando sprites de pixel art
- Sistema de tiles aleatórios implementado para **paredes** (4 variações: wall1-4)
  - Tiles de 6×32px com seleção aleatória
  - 5 tiles por parede (160px ÷ 32px = 5)
  - Cada parede tem combinação única de tiles
- Floor e paredes com mesma espessura (6px) para harmonia visual
- Collision do floor ajustada para 1px no topo (personagens alinhados corretamente)
