#!/usr/bin/env bash

# Setup script for new projects using dev-standards
# Usage: ./scripts/setup-new-project.sh my-project-name

set -e  # Exit on error

PROJECT_NAME=$1
DEV_STANDARDS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ -z "$PROJECT_NAME" ]; then
  echo -e "${YELLOW}Usage: $0 <project-name>${NC}"
  echo "Example: $0 my-new-app"
  exit 1
fi

echo -e "${BLUE}🚀 Setting up new project: ${PROJECT_NAME}${NC}"
echo ""

# Create project directory
if [ -d "$PROJECT_NAME" ]; then
  echo -e "${YELLOW}⚠️  Directory ${PROJECT_NAME} already exists. Continuing anyway...${NC}"
else
  mkdir "$PROJECT_NAME"
  echo -e "${GREEN}✓${NC} Created project directory"
fi

cd "$PROJECT_NAME"

# Initialize Vite + React + TypeScript project
echo -e "${BLUE}📦 Initializing Vite project...${NC}"
npm create vite@latest . -- --template react-ts
echo -e "${GREEN}✓${NC} Vite project initialized"

# Install dependencies
echo -e "${BLUE}📦 Installing base dependencies...${NC}"
npm install

# Install standard dependencies
echo -e "${BLUE}📦 Installing standard dependencies...${NC}"
npm install @tanstack/react-query zustand react-router-dom zod react-hook-form @hookform/resolvers
npm install -D @types/node

echo -e "${GREEN}✓${NC} Dependencies installed"

# Copy templates
echo -e "${BLUE}📄 Copying templates...${NC}"

cp "${DEV_STANDARDS_PATH}/templates/CLAUDE.md.template" ./CLAUDE.md
echo -e "${GREEN}✓${NC} Copied CLAUDE.md"

cp "${DEV_STANDARDS_PATH}/templates/.env.example.template" ./.env.example
echo -e "${GREEN}✓${NC} Copied .env.example"

# Create .env.local from .env.example
cp ./.env.example ./.env.local
echo -e "${GREEN}✓${NC} Created .env.local (fill in values manually)"

# Copy CI workflow
mkdir -p .github/workflows
cp "${DEV_STANDARDS_PATH}/ci-cd/ci.yml" .github/workflows/ci.yml
echo -e "${GREEN}✓${NC} Copied GitHub Actions CI workflow"

# Create Bulletproof React structure
echo -e "${BLUE}📁 Creating Bulletproof React structure...${NC}"

mkdir -p src/{app,components,config,features,hooks,lib,stores,types,utils,test}
mkdir -p src/app/{routes,providers}
mkdir -p src/components/{ui,layouts,shared}

# Create placeholder files
cat > src/config/env.ts << 'EOF'
import { z } from 'zod';

const envSchema = z.object({
  VITE_SUPABASE_URL: z.string().url(),
  VITE_SUPABASE_ANON_KEY: z.string().min(1),
});

export const env = envSchema.parse({
  VITE_SUPABASE_URL: import.meta.env.VITE_SUPABASE_URL,
  VITE_SUPABASE_ANON_KEY: import.meta.env.VITE_SUPABASE_ANON_KEY,
});
EOF

cat > src/test/setup.ts << 'EOF'
import '@testing-library/jest-dom/vitest';
import { beforeEach } from 'vitest';
import { vi } from 'vitest';

beforeEach(() => {
  vi.clearAllMocks();
});
EOF

echo -e "${GREEN}✓${NC} Created folder structure"

# Update package.json scripts
echo -e "${BLUE}📝 Updating package.json scripts...${NC}"

npm pkg set scripts.dev="vite"
npm pkg set scripts.build="tsc -b && vite build"
npm pkg set scripts.preview="vite preview"
npm pkg set scripts.lint="eslint src/ --ext .ts,.tsx --max-warnings 0"
npm pkg set scripts.type-check="tsc --noEmit"
npm pkg set scripts.test="vitest"
npm pkg set scripts.test:run="vitest run"

echo -e "${GREEN}✓${NC} Updated npm scripts"

# Create tsconfig paths
echo -e "${BLUE}⚙️  Configuring TypeScript paths...${NC}"

cat > tsconfig.json << 'EOF'
{
  "files": [],
  "references": [
    { "path": "./tsconfig.app.json" },
    { "path": "./tsconfig.node.json" }
  ],
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
EOF

cat > tsconfig.app.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "isolatedModules": true,
    "moduleDetection": "force",
    "noEmit": true,
    "jsx": "react-jsx",

    "strict": true,
    "noImplicitAny": true,
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "noUncheckedIndexedAccess": true,

    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"]
}
EOF

echo -e "${GREEN}✓${NC} TypeScript configured with strict mode and path aliases"

# Create .gitignore
cat > .gitignore << 'EOF'
# Dependencies
node_modules/

# Build
dist/
.next/
build/

# Environment (NEVER commit)
.env
.env.local
.env.production
.env.*.local

# OS
.DS_Store
Thumbs.db

# Editor
.vscode/settings.json
.idea/

# Debug
*.log
npm-debug.log*

# Testing
coverage/
playwright-report/

# Temp
*.tmp
*.swp
EOF

echo -e "${GREEN}✓${NC} Created .gitignore"

# Initialize git
echo -e "${BLUE}🔧 Initializing git repository...${NC}"
git init
git add .
git commit -m "chore: initial project setup from dev-standards

- Vite + React 19 + TypeScript
- Bulletproof React structure
- Standard dependencies installed
- CI workflow configured
- Templates copied

🤖 Generated with [Claude Code](https://claude.com/claude-code)"

echo -e "${GREEN}✓${NC} Git repository initialized with initial commit"

echo ""
echo -e "${GREEN}✨ Project setup complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. cd $PROJECT_NAME"
echo "2. Fill in values in .env.local"
echo "3. Update CLAUDE.md with project-specific details"
echo "4. Install shadcn/ui: npx shadcn@latest init"
echo "5. Read errors/common-errors-and-lessons.md before coding"
echo "6. npm run dev"
echo ""
echo -e "${YELLOW}Remember to:${NC}"
echo "- Set up branch protection on GitHub (see ci-cd/ci-cd-guide.md)"
echo "- Share git/git-workflow.md with your team"
echo "- Run security checklist before first deploy"
