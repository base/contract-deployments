# Code Formatting & Linting Setup

This workspace uses **Prettier** for code formatting and **ESLint** for linting to ensure consistent code style across all packages.

## 🛠️ Tools Used

- **Prettier**: Code formatter for TypeScript, JavaScript, JSON, and Markdown
- **ESLint**: Linter for TypeScript with TypeScript-specific rules
- **VS Code Integration**: Automatic formatting on save

## 📁 Configuration Files (Global)

- `.prettierrc` - Prettier configuration
- `eslint.config.js` - ESLint configuration (flat config format)
- `.prettierignore` - Files to exclude from formatting
- `.vscode/settings.json` - VS Code settings for auto-formatting
- `.vscode/extensions.json` - Recommended VS Code extensions

## 🚀 Available Scripts (Run from workspace root)

```bash
# Format all TypeScript files across all packages
npm run format

# Check formatting without making changes
npm run format:check

# Run ESLint across all packages
npm run lint

# Run ESLint and auto-fix issues
npm run lint:fix

# Format and lint in one command
npm run format:lint
```

## ⚙️ VS Code Setup

### Required Extensions

Install these VS Code extensions for the best experience:

1. **Prettier - Code formatter** (`esbenp.prettier-vscode`)
2. **ESLint** (`dbaeumer.vscode-eslint`)
3. **TypeScript and JavaScript Language Features** (built-in)

### Automatic Formatting

The workspace is configured to automatically:

- Format code on save
- Fix ESLint issues on save
- Organize imports on save
- Trim trailing whitespace
- Insert final newline

## 📋 Formatting Rules

### Prettier Configuration

```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "arrowParens": "avoid",
  "endOfLine": "lf"
}
```

### ESLint Rules

- TypeScript recommended rules
- Prettier integration (formatting errors show as ESLint errors)
- Unused variables must be prefixed with `_` or removed
- `any` types show as warnings (not errors)
- Node.js globals (console, process, etc.) are recognized
- Jest globals (describe, it, expect, etc.) are recognized in test files

## 🚫 Excluded Files/Folders

The following are excluded from formatting and linting:

- `node_modules/` (all packages)
- `dist/` and `build/` (all packages)
- `examples/` (all packages) - Contains external/unformatted code
- `*.js` files (except config files)
- Generated files (`*.d.ts`)

## 🔧 Package-Level Setup

Individual packages no longer need their own formatting configuration. The global setup handles:

- **CLI package** (`cli/`) - TypeScript source code
- **Web package** (`web/`) - React/TypeScript code (when added)
- **Docs** (`docs/`) - Markdown files

## 🎯 Best Practices

1. **Always run formatting before committing**:

   ```bash
   npm run format:lint
   ```

2. **Fix linting warnings** (especially `any` types):

   - Replace `any` with specific types when possible
   - Use `unknown` for truly unknown types
   - Use type assertions sparingly

3. **Unused variables**:

   - Remove unused variables when possible
   - Prefix with `_` if needed for API compliance: `_unusedParam`
   - Use destructuring with rest for partial usage: `const { used, ...rest } = obj`

4. **Import organization**:
   - Imports are automatically organized on save
   - External packages first, then internal modules
   - Use relative imports for local files

## 🚨 Common Issues

### ESLint Errors

- **"'describe' is not defined"**: Fixed with Jest globals in test files
- **"Unexpected any"**: Replace with specific types or use `unknown`
- **"unused variable"**: Remove or prefix with `_`

### Prettier Conflicts

- ESLint and Prettier are configured to work together
- Prettier handles formatting, ESLint handles code quality
- Run `npm run format:lint` to fix both

### VS Code Not Formatting

1. Check that Prettier extension is installed and enabled
2. Verify `.vscode/settings.json` is present in workspace root
3. Check that the file type is supported (`.ts`, `.tsx`, `.js`, `.json`, `.md`)
4. Try reloading VS Code window

## 📊 Current Status

✅ **Formatting**: Global configuration across all packages
✅ **Linting**: 0 errors, 4 warnings (all `any` types)
✅ **VS Code**: Auto-format on save configured
✅ **Scripts**: All npm scripts working from workspace root
✅ **Exclusions**: Examples folder properly excluded

The 4 remaining warnings are for `any` types that can be improved over time but don't block development.

## 🔄 Migration from Package-Level Config

If you had package-level formatting configuration:

1. Remove `.prettierrc`, `.prettierignore`, `eslint.config.js` from individual packages
2. Remove formatting dependencies from package-level `package.json`
3. Remove formatting scripts from package-level `package.json`
4. Use the global scripts from workspace root instead
