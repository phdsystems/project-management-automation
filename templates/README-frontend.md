# Frontend Application

## Overview

This is the frontend application for the project.

## Tech Stack

- React 18
- TypeScript
- Vite
- Tailwind CSS

## Getting Started

```bash
npm install
npm run dev
```

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run test` - Run tests
- `npm run lint` - Lint code

## Project Structure

```
src/
├── components/
├── pages/
├── hooks/
├── utils/
└── App.tsx
```

## Development Guidelines

### Code Style

- Use TypeScript for all new files
- Follow ESLint rules
- Use functional components with hooks
- Implement proper error boundaries

### Testing

- Write unit tests for components
- Use React Testing Library
- Maintain test coverage above 80%

### Performance

- Lazy load routes and heavy components
- Optimize images and assets
- Use React.memo for expensive renders
- Monitor bundle size

## Deployment

The application is automatically deployed on push to `main` branch via GitHub Actions.

## Environment Variables

Copy `.env.example` to `.env.local` and configure:

```bash
VITE_API_URL=http://localhost:3000
VITE_APP_NAME=My App
```

## Contributing

1. Create a feature branch from `develop`
2. Make your changes
3. Write/update tests
4. Submit a pull request
5. Wait for code review

## License

See LICENSE file for details.
