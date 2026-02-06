# Player - Guia de Variáveis

Arquivo principal: `scripts/player.gd`

---

## Movimento Normal (linhas 33-38)

| Variável | Valor | O que faz |
|---|---|---|
| `SPEED` | **350.0** | Velocidade horizontal do auto-walk. Maior = mais rápido |
| `JUMP_VELOCITY` | **-370.0** | Força do pulo (negativo = pra cima). Mais negativo = pulo mais alto |
| `ACCELERATION` | 1000.0 | Quão rápido atinge a velocidade máxima no chão |
| `FRICTION` | 200.0 | Desaceleração no chão (não está sendo usada no auto-walk) |
| `AIR_RESISTANCE` | 50.0 | Controle de direção no ar. Menor = mais "escorregadio" |
| `JUMP_RELEASE_FORCE` | **-230.0** | Velocidade ao soltar o botão de pulo cedo. Controla o "pulo curto" |

### Como testar velocidade
- Quer o player **mais lento**? Diminua `SPEED` (ex: 300)
- Quer o player **mais rápido**? Aumente `SPEED` (ex: 450)
- Quer **pulo mais baixo**? Aumente `JUMP_VELOCITY` para mais perto de 0 (ex: -320)
- Quer **pulo mais alto**? Diminua `JUMP_VELOCITY` (ex: -450)
- `JUMP_RELEASE_FORCE` deve ser sempre **menos negativo** que `JUMP_VELOCITY` (é o pulo "cortado")

---

## Escada (linha 41)

| Variável | Valor | O que faz |
|---|---|---|
| `CLIMB_SPEED` | 250.0 | Velocidade de subida na escada |

---

## Timers de Pulo (linhas 46-49)

| Variável | Valor | O que faz |
|---|---|---|
| `COYOTE_TIME` | 0.1s | Tempo extra pra pular depois de sair da plataforma |
| `JUMP_BUFFER_TIME` | 0.1s | Tempo que "guarda" o input de pulo antes de tocar o chão |

Aumentar esses valores torna o jogo mais responsivo/fácil. Diminuir torna mais preciso/difícil.

---

## Gravidade (linha 52)

```gdscript
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
```
Controlada em **Project Settings > Physics > 2D > Default Gravity** (padrão Godot: 980).
Maior = cai mais rápido. Afeta diretamente a sensação do pulo.

---

## Combate / Sobrevivência (linhas 3-4)

| Variável | Valor | O que faz |
|---|---|---|
| `INVULNERABILITY_TIME` | 1.5s | Tempo de invulnerabilidade após levar dano |

---

## Ímã (linhas 10-11)

| Variável | Valor | O que faz |
|---|---|---|
| `MAGNET_RANGE` | 150.0 | Raio de atração dos coletáveis |

---

## Boss Fight (linhas 19-20)

| Variável | Valor | O que faz |
|---|---|---|
| `BOSS_SHOOT_COOLDOWN` | 0.3s | Tempo entre tiros no boss 1 |
| Boss 3 speed | `SPEED * 0.5` | Player anda a 50% da velocidade no boss 3 (linha 739) |

---

## Lançamento / Canhão

Velocidade durante lançamento do canhão: `SPEED * 0.5` (linha 108)
- Na intro cutscene: velocidade horizontal = 0 (linha 106)

---

## GameManager (variáveis globais)

Arquivo: `scripts/game_manager.gd`

| Variável | O que faz |
|---|---|
| `filled_hearts` | Vida do player (0-3) |
| `DIAMONDS_BEFORE_HEART` | Diamantes para ganhar 1 coração |
| `metal_active` | Modo metal (escudo) ativo? |
| `magnet_active` | Ímã ativo? |
| `invincible_active` | Modo invencível ativo? |
| `mist_active` | Modo névoa ativo? |
| `MIST_DURATION` | Duração da névoa |
| `INVINCIBLE_DURATION` | Duração do invencível |

---

## Valores anteriores (referência)

| Variável | Antes | Agora |
|---|---|---|
| `SPEED` | 400.0 | **350.0** |
| `JUMP_VELOCITY` | -400.0 | **-370.0** |
| `JUMP_RELEASE_FORCE` | -250.0 | **-230.0** |
