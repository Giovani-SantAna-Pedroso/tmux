
#!/bin/bash
# ──────────────────────────────────────────────
# Script para alternar entre configurações do Sway
# e ajustar a saída de áudio automaticamente
#
# Uso: ./set_sway_mode.sh [4k|ultra|gaming|remote|help]
# ──────────────────────────────────────────────

BASE_DIR="$(dirname "$(realpath "$0")")/.."
TARGET="$BASE_DIR/config"

# Cores
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# Nomes exatos das saídas
HDMI_SINK="alsa_output.pci-0000_03_00.1.hdmi-stereo"
HEADPHONES_SINK="alsa_output.pci-0000_03_00.6.analog-stereo"

show_help() {
  echo -e "${YELLOW}Uso:${RESET} $0 {4k|ultra|gaming|remote|help}"
  echo
  echo "Alterna o arquivo config do Sway e muda a saída de áudio:"
  echo "  4k       → sway_4k.conf + saída HDMI"
  echo "  ultra    → sway_ultra.conf + saída Headphones"
  echo "  gaming   → sway_ultra_gaming.conf + saída Headphones"
  echo "  remote   → sway_remote.conf (Alt como mod) + Headphones"
  echo "  help     → mostra esta ajuda"
  echo
}

# Função para mudar saída de áudio
set_audio_output() {
  local sink_name="$1"

  if pactl list short sinks | grep -q "$sink_name"; then
    pactl set-default-sink "$sink_name"

    # Move fluxos ativos para o novo sink
    pactl list short sink-inputs | while read -r input; do
      input_id=$(echo "$input" | awk '{print $1}')
      pactl move-sink-input "$input_id" "$sink_name"
    done

    echo -e "${GREEN}🔊 Saída de áudio alterada para:${RESET} $sink_name"
  else
    echo -e "${RED}⚠️ Saída de áudio não encontrada:${RESET} $sink_name"
    echo "Use 'pactl list short sinks' para verificar os nomes disponíveis."
  fi
}

# Nenhum argumento → ajuda
if [[ -z "$1" ]]; then
  show_help
  exit 0
fi

# Seleciona configuração e saída de áudio
case "$1" in
  mirror)
    SOURCE="$BASE_DIR/sway_mirror.conf"
    AUDIO_TARGET="$HDMI_SINK"
    ;;
  4k)
    SOURCE="$BASE_DIR/sway_4k.conf"
    AUDIO_TARGET="$HDMI_SINK"
    ;;
  ultra)
    SOURCE="$BASE_DIR/sway_ultra.conf"
    AUDIO_TARGET="$HEADPHONES_SINK"
    ;;
  gaming)
    SOURCE="$BASE_DIR/sway_ultra_gaming.conf"
    AUDIO_TARGET="$HEADPHONES_SINK"
    ;;
  remote)
    SOURCE="$BASE_DIR/sway_remote.conf"
    AUDIO_TARGET="$HEADPHONES_SINK"
    ;;
  help|-h|--help)
    show_help
    exit 0
    ;;
  *)
    echo -e "${RED}❌ Erro:${RESET} argumento inválido '$1'"
    echo "Use '$0 help' para ver as opções disponíveis."
    exit 1
    ;;
esac

# Verifica se o arquivo existe
if [[ ! -f "$SOURCE" ]]; then
  echo -e "${RED}❌ Arquivo de configuração não encontrado:${RESET} $SOURCE"
  exit 2
fi

# Copia a configuração e aplica
cp "$SOURCE" "$TARGET"
echo -e "${GREEN}✅ Configuração aplicada:${RESET} $(basename "$SOURCE")"

# Muda a saída de áudio
set_audio_output "$AUDIO_TARGET"

# Notificação gráfica
if command -v notify-send &>/dev/null; then
  notify-send "Sway" "Configuração aplicada: $(basename "$SOURCE")"
fi

# Recarrega Sway se estiver rodando
if command -v swaymsg &>/dev/null; then
  swaymsg reload &>/dev/null
fi
