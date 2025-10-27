# Backend Application

## Overview

This is the backend API service for the project.

## Tech Stack

- Node.js 20 LTS
- Express.js / NestJS
- TypeScript
- PostgreSQL
- Redis
- JWT Authentication

## Getting Started

```bash
npm install
npm run dev
```

## Available Scripts

- `npm run dev` - Start development server with hot reload
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run test` - Run tests
- `npm run test:watch` - Run tests in watch mode
- `npm run lint` - Lint code
- `npm run migrate` - Run database migrations

## Project Structure

```
src/
├── controllers/
├── services/
├── models/
├── routes/
├── middleware/
├── config/
├── utils/
└── app.ts
```

## API Documentation

API documentation is available at `/api/docs` when running the development server.

## Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Server
PORT=3000
NODE_ENV=development

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
REDIS_URL=redis://localhost:6379

# Authentication
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d

# External APIs
API_KEY=your-api-key
```

## Database

### Migrations

```bash
# Create new migration
npm run migrate:create -- migration-name

# Run migrations
npm run migrate:up

# Rollback migrations
npm run migrate:down
```

### Seeding

```bash
# Seed database with test data
npm run seed
```

## Testing

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- path/to/test.spec.ts
```

## Development Guidelines

### Code Style

- Use TypeScript for all new files
- Follow ESLint and Prettier rules
- Use async/await over callbacks
- Implement proper error handling
- Write meaningful commit messages

### API Design

- Follow RESTful conventions
- Use proper HTTP status codes
- Validate request data
- Return consistent error responses
- Document all endpoints

### Security

- Validate and sanitize all inputs
- Use parameterized queries (prevent SQL injection)
- Implement rate limiting
- Use HTTPS in production
- Keep dependencies updated

### Performance

- Implement database indexing
- Use Redis for caching
- Optimize N+1 queries
- Monitor API response times
- Implement pagination for large datasets

## Deployment

The application is automatically deployed on push to `main` branch via GitHub Actions.

### Production Checklist

- [ ] Environment variables configured
- [ ] Database migrations run
- [ ] SSL certificates configured
- [ ] Monitoring and logging enabled
- [ ] Backup strategy in place

## Monitoring

- **Logs:** Available in `/logs` directory or cloud logging service
- **Metrics:** Prometheus metrics exposed at `/metrics`
- **Health Check:** Available at `/health`

## Contributing

1. Create a feature branch from `develop`
2. Make your changes
3. Write/update tests
4. Update API documentation
5. Submit a pull request
6. Wait for code review

## Troubleshooting

### Common Issues

**Database connection fails:**
- Check DATABASE_URL is correct
- Verify PostgreSQL is running
- Check network connectivity

**Redis connection fails:**
- Check REDIS_URL is correct
- Verify Redis is running

**Tests failing:**
- Clear test database: `npm run test:db:reset`
- Check environment variables

## License

See LICENSE file for details.
