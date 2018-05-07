rm doc.html || 0
rm -rf ./assets || 0
cp -r ./content/assets ./assets
cat content/*.md > rendered.md
markdown-cli-renderer rendered.md doc.html
rm rendered.md