# Guia de Parallax - High Up

## Visão Geral

O jogo usa um sistema de parallax vertical com **4 camadas** que criam profundidade à medida que o jogador sobe. Cada camada se move em velocidades diferentes para criar o efeito de parallax.

## Estrutura das Camadas

### Layer 1 - Sky (Céu)
- **Nome do arquivo**: `layer1_sky.png`
- **Dimensões**: 360×1280px
- **Velocidade**: 0.1x (move apenas 10% da velocidade da câmera)
- **Repetição**: A cada 1280px verticalmente
- **Cor placeholder**: Azul claro `#87CEEB`
- **Elementos sugeridos**:
  - Céu com gradiente (azul claro embaixo → azul escuro/roxo em cima)
  - Nuvens muito distantes (opcionais)
  - Estrelas no topo (opcionais)
  - **IMPORTANTE**: Deve ser tileable verticalmente (topo conecta com a base)

### Layer 2 - Far Trees (Árvores Distantes)
- **Nome do arquivo**: `layer2_far_trees.png`
- **Dimensões**: 360×640px
- **Velocidade**: 0.3x (move 30% da velocidade da câmera)
- **Repetição**: A cada 640px verticalmente
- **Cor placeholder**: Verde escuro dessaturado `#5D8A66`
- **Elementos sugeridos**:
  - Silhuetas de árvores ao longe
  - Montanhas ou colinas distantes
  - Nuvens médias
  - Pássaros voando (pequenos, distantes)
  - **Estilo**: Formas simples, baixo detalhe (2-3 cores)
  - **Transparência**: Pode usar alpha para sobrepor camadas

### Layer 3 - Mid Trees (Árvores Médias)
- **Nome do arquivo**: `layer3_mid_trees.png`
- **Dimensões**: 360×480px
- **Velocidade**: 0.6x (move 60% da velocidade da câmera)
- **Repetição**: A cada 480px verticalmente
- **Cor placeholder**: Verde médio `#4A6B4E`
- **Elementos sugeridos**:
  - Galhos atravessando os lados da tela
  - Troncos de árvores laterais
  - Folhas em médio detalhe
  - Cipós, vinhas
  - **Estilo**: Detalhes médios, formas mais definidas
  - **Cores**: Mais saturadas que a camada 2

### Layer 4 - Close Leaves (Primeiro Plano)
- **Nome do arquivo**: `layer4_close_leaves.png`
- **Dimensões**: 360×240px
- **Velocidade**: 0.85x (move 85% da velocidade da câmera)
- **Repetição**: A cada 240px verticalmente
- **Cor placeholder**: Verde escuro saturado `#3D5A3F` (70% alpha)
- **Elementos sugeridos**:
  - Folhas grandes bem próximas
  - Galhos em primeiro plano
  - Detalhes de casca de árvore
  - Partículas de luz (fireflies, opcional)
  - **Estilo**: Alto detalhe, cores saturadas
  - **Transparência**: Use 60-80% de opacidade para não obstruir o gameplay

## Como o Sistema Funciona

### Velocidades de Parallax

```
Câmera move 100px para cima
├─ Layer 1 (Sky): move 10px (0.1x)
├─ Layer 2 (Far): move 30px (0.3x)
├─ Layer 3 (Mid): move 60px (0.6x)
└─ Layer 4 (Close): move 85px (0.85x)
```

Quanto **menor** a velocidade, mais **distante** o objeto parece estar.

### Repetição Infinita

Cada camada se repete verticalmente usando o sistema `Parallax2D`:
- O Godot automaticamente repete a textura quando o jogador passa da altura definida
- Exemplo: Layer 2 (640px) se repete a cada 640px de movimento vertical
- `repeat_times = 20` garante que há tiles suficientes para uma subida longa

## Paleta de Cores Recomendada

### Profundidade por Cor

| Camada | Saturação | Brilho | Contraste | Exemplo |
|--------|-----------|--------|-----------|---------|
| **Layer 1** | Baixa | Alto | Baixo | `#87CEEB` (céu) |
| **Layer 2** | Média-Baixa | Médio | Médio | `#5D8A66`, `#7BA87D` |
| **Layer 3** | Média | Médio | Médio-Alto | `#4A6B4E`, `#6B8E4A` |
| **Layer 4** | Alta | Médio-Baixo | Alto | `#3D5A3F`, `#8FBC5A` |

### Dica: Efeito Atmosférico
Adicione uma leve "névoa" nas camadas distantes:
- Use overlay semi-transparente branco/azul claro
- Reduza o contraste conforme fica mais longe
- Isso simula a atmosfera e aumenta a sensação de profundidade

## Como Criar Texturas Tileables (Repetíveis)

### Método 1: Aseprite
1. Crie sua imagem (ex: 360×640px)
2. Vá em `View → Tiled Mode → Both` (ou `Grid → Tile Settings`)
3. Desenhe normalmente - o Aseprite mostra como ficará a repetição
4. Teste se o topo conecta perfeitamente com a base

### Método 2: Offset Manual
1. Desenhe sua textura
2. Desloque verticalmente por 50% (320px em uma textura de 640px)
3. Corrija as costuras na junção
4. Repita até ficar perfeito

### Teste de Tile
Você pode duplicar a imagem várias vezes verticalmente para visualizar:
```
┌─────────┐
│ Textura │ ← Original
├─────────┤
│ Textura │ ← Cópia 1
├─────────┤
│ Textura │ ← Cópia 2
└─────────┘
```
Não deve haver "costura" visível entre as cópias.

## Como Adicionar Suas Texturas

### Opção 1: Substituir Placeholders (Automático)

1. **Crie os arquivos PNG**:
   ```
   assets/parallax/
     layer1_sky.png          (360×1280px)
     layer2_far_trees.png    (360×640px)
     layer3_mid_trees.png    (360×480px)
     layer4_close_leaves.png (360×240px)
   ```

2. **No Godot, abra a cena**: `scenes/main.tscn`

3. **Para cada camada**:
   - Selecione o node (ex: `ParallaxBackground/Layer1_Sky/Sprite2D`)
   - No inspetor, arraste sua textura para a propriedade `Texture`
   - O placeholder colorido desaparecerá automaticamente

### Opção 2: Carregar por Código

No script `parallax_background.gd`, use a função `load_texture()`:

```gdscript
# Exemplo: Carregar todas as texturas
func _ready():
    load_texture(1, "res://assets/parallax/layer1_sky.png")
    load_texture(2, "res://assets/parallax/layer2_far_trees.png")
    load_texture(3, "res://assets/parallax/layer3_mid_trees.png")
    load_texture(4, "res://assets/parallax/layer4_close_leaves.png")
```

## Arquivos Relacionados

### Scripts
- `scripts/parallax_background.gd` - Gerencia todas as camadas de parallax
  - Constantes de velocidade, dimensões e cores
  - Função `setup_layer()` - configura cada camada
  - Função `load_texture()` - carrega texturas dinamicamente

### Cenas
- `scenes/main.tscn` - Contém o node `ParallaxBackground` com as 4 camadas
  - `Layer1_Sky` (Parallax2D)
  - `Layer2_FarTrees` (Parallax2D)
  - `Layer3_MidTrees` (Parallax2D)
  - `Layer4_CloseLeaves` (Parallax2D)

## Modificar Velocidades ou Dimensões

### Alterar Velocidade de uma Camada

Em `scripts/parallax_background.gd`:
```gdscript
const LAYER3_SPEED = 0.6   # Valor entre 0.0 (parado) e 1.0 (mesma velocidade da câmera)
```

### Alterar Altura de Repetição

Em `scripts/parallax_background.gd`:
```gdscript
const LAYER3_HEIGHT = 480   # Altura em pixels antes de repetir
```

**IMPORTANTE**: Se alterar a altura, crie uma nova textura com as dimensões correspondentes!

## Dicas de Design

### 1. Teste com Cores Primeiro
Antes de criar pixel art detalhado:
- Use cores sólidas diferentes para cada camada
- Teste as velocidades e veja se o efeito está agradável
- Ajuste as velocidades conforme necessário

### 2. Mantenha Consistência
- Use a mesma paleta de cores em todas as camadas
- Mantenha o estilo visual coerente
- Considere a iluminação (de onde vem a luz?)

### 3. Não Sobrecarregue
- Camadas frontais (Layer 4) devem ser **esparsas**
- Muito detalhe na frente pode cansar a visão
- Deixe "espaços vazios" para o olho descansar

### 4. Pense na Subida Infinita
- O jogador vai ver essas texturas MUITAS vezes
- Crie variações interessantes mas não repetitivas
- Evite padrões muito óbvios que ficam enjoativos

## Status Atual

- ✅ Sistema de 4 camadas implementado
- ✅ Placeholders coloridos funcionando
- ✅ Velocidades configuradas para parallax vertical
- ✅ Repetição infinita ativa
- ⏳ Aguardando texturas de pixel art (você vai criar!)

## Próximos Passos

1. Criar `layer1_sky.png` (360×1280px)
2. Criar `layer2_far_trees.png` (360×640px)
3. Criar `layer3_mid_trees.png` (360×480px)
4. Criar `layer4_close_leaves.png` (360×240px)
5. Adicionar as texturas no Godot
6. Testar e ajustar velocidades se necessário
