#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Fonction pour convertir le code TypeScript compilé en code n8n
function convertToN8nCode(filePath) {
  if (!fs.existsSync(filePath)) {
    console.log(`❌ File not found: ${filePath}`);
    return;
  }

  let content = fs.readFileSync(filePath, 'utf8');
  
  // Remplacements pour n8n
  const replacements = [
    // Remplacer this.getInputData() par $input.all()
    {
      from: /this\.getInputData\(\)/g,
      to: '$input.all()'
    },
    // Supprimer les lignes d'export CommonJS
    {
      from: /"use strict";\s*\n/g,
      to: ''
    },
    {
      from: /Object\.defineProperty\(exports, "__esModule", \{ value: true \}\);\s*\n/g,
      to: ''
    },
    // Supprimer la déclaration de fonction (garder juste le corps)
    {
      from: /^function execute\(\) \{\s*\n/gm,
      to: ''
    },
    // Supprimer la dernière accolade de fermeture avec plus de flexibilité
    {
      from: /\n*\s*\}\s*$/g,
      to: ''
    }
  ];

  // Appliquer tous les remplacements
  replacements.forEach(replacement => {
    content = content.replace(replacement.from, replacement.to);
  });

  // Nettoyer les lignes vides en début/fin et l'indentation superflue
  content = content.trim();
  
  // Supprimer l'indentation en début de chaque ligne
  content = content.replace(/^    /gm, '');

  return content;
}

// Fonction principale
function buildForN8n() {
  console.log('🔨 Compiling TypeScript...');
  
  try {
    // Compiler TypeScript
    execSync('npx tsc', { stdio: 'inherit' });
    console.log('✅ TypeScript compilation successful');

    // Convertir tous les fichiers .js dans dist/
    const distDir = './dist';
    if (!fs.existsSync(distDir)) {
      console.log('❌ dist/ directory not found');
      return;
    }

    const jsFiles = fs.readdirSync(distDir).filter(file => file.endsWith('.js') && !file.includes('.n8n.'));
    
    jsFiles.forEach(file => {
      const filePath = path.join(distDir, file);
      const n8nCode = convertToN8nCode(filePath);
      
      if (n8nCode) {
        // Créer le fichier .n8n.js avec le code prêt pour n8n
        const n8nFilePath = filePath.replace('.js', '.n8n.js');
        fs.writeFileSync(n8nFilePath, n8nCode);
        console.log(`✅ Created n8n-ready code: ${path.basename(n8nFilePath)}`);
        
        // Afficher un aperçu
        console.log(`\n📋 Code ready for n8n (${path.basename(n8nFilePath)}):`);
        console.log('─'.repeat(50));
        console.log(n8nCode.substring(0, 200) + (n8nCode.length > 200 ? '...' : ''));
        console.log('─'.repeat(50));
      }
    });

  } catch (error) {
    console.error('❌ Build failed:', error.message);
  }
}

// Lancer le build
buildForN8n();