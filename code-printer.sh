#!/bin/bash

# Parametrización del directorio de trabajo
CODE_PATH="$(pwd)/src"

# Verificamos si se proporcionó un directorio destino como argumento
if [ $# -ge 1 ]; then
    OUTPUT_DIR="$1"
    # Asegurar que el directorio termina con una barra
    [[ "$OUTPUT_DIR" != */ ]] && OUTPUT_DIR="${OUTPUT_DIR}/"
else
    # Si no hay argumento, usamos el directorio actual
    OUTPUT_DIR="$(pwd)/"
fi

# Archivo de salida en el directorio especificado
OUTPUT_FILE="${OUTPUT_DIR}Codigo.txt"

# Asegurarse de que el directorio destino existe
mkdir -p "$(dirname "$OUTPUT_FILE")"

clear &&
cd "$CODE_PATH" && {
  echo "Generando archivo en: $OUTPUT_FILE"

  # Primero escribimos la estructura de directorios
  echo -e "\`\`\`" | tee "$OUTPUT_FILE"
  tree -P '*.cs' -P '*.c' -P '*.h' -P '*.sh' -P "Makefile" --prune ./ | tee -a "$OUTPUT_FILE"
  echo -e "\`\`\`" | tee -a "$OUTPUT_FILE"
  echo -e "" | tee -a "$OUTPUT_FILE"

  # Procesamos cada archivo, excluyendo Codigo.txt y show_code.sh
  for file in $(find . -type f \( -path "./bin" -o -path "./obj" -o -path "./.idea" \) -prune -o -type f \( -iname "*.c" -o -iname "*.txt" -o -iname "*.h" -o -iname "*.js" -o -iname "*.vue" -o -iname "*.html" -o -iname "*.css" -o -iname "*.scss" -o -iname "*.env" -o -iname "*.csproj" -o -iname "*.sln" -o -iname "*.cs" -o -iname "*.user" -o -iname "*.xml" -o -iname "*.md" -o -iname "*.mdx" -o -iname "*.sh" -o -iname "Makefile" \) -print); do
    # Excluimos Codigo.txt y show_code.sh
    if [[ "$file" == *"Codigo.txt"* || "$file" == *"show_code.sh"* ]]; then
      continue
    fi

    lines=$(wc -l < "$file")

    echo -e "NOMBRE DEL ARCHIVO: \`$file\` ($lines Líneas)" | tee -a "$OUTPUT_FILE"
    echo -e "\`\`\`${file##*.}" | tee -a "$OUTPUT_FILE"
    head -n 1500 "$file" | tee -a "$OUTPUT_FILE"

    if [ "$lines" -gt 1500 ]; then
      echo -e "... (...continua...)" | tee -a "$OUTPUT_FILE"
    fi

    echo -e "" | tee -a "$OUTPUT_FILE"
    echo -e "\`\`\`" | tee -a "$OUTPUT_FILE"
    echo -e "" | tee -a "$OUTPUT_FILE"
    echo -e "" | tee -a "$OUTPUT_FILE"
  done

  # Calculamos el total de líneas, excluyendo Codigo.txt y show_code.sh
  TOTAL_LINES=$(find . -type f \( -path "./bin" -o -path "./obj" -o -path "./.idea" \) -prune -o -type f \( -iname "*.c" -o -iname "*.txt" -o -iname "*.h" -o -iname "*.js" -o -iname "*.vue" -o -iname "*.html" -o -iname "*.css" -o -iname "*.scss" -o -iname "*.env" -o -iname "*.csproj" -o -iname "*.sln" -o -iname "*.cs" -o -iname "*.user" -o -iname "*.xml" -o -iname "*.md" -o -iname "*.mdx" -o -iname "*.sh" -o -iname "Makefile" \) -print | grep -v "Codigo.txt" | grep -v "show_code.sh" | xargs wc -l 2>/dev/null | tail -n 1 | awk '{print $1}')

  # Añadimos el total al final
  echo -e "Total: $TOTAL_LINES líneas" | tee -a "$OUTPUT_FILE"

  echo "Archivo generado con éxito en: $OUTPUT_FILE"
}
