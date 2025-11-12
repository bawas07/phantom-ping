# Implementation Plan

- [x] 1. Set up backend project structure

  - Create root `phantom-ping` directory with `backend/` subdirectory
  - Initialize Bun project in `backend/` directory with TypeScript configuration
  - Create `.gitignore` file for backend
  - Set up basic project structure (src/, tests/, etc.)
  - _Requirements: 13.1, 13.2, 13.3, 13.4_

- [x] 1.1 Set up frontend project structure

  - Create `frontend/` subdirectory in root `phantom-ping` directory
  - Initialize Flutter project in `frontend/` directory
  - Create `.gitignore` file for frontend
  - Set up basic Flutter project structure
  - _Requirements: 13.1, 13.2, 13.3, 13.4_

- [x] 2. Implement backend database schema and migrations

  - [x] 2.1 Set up database connection and migration system

    - Install database driver (better-sqlite3 or pg for PostgreSQL)
    - Create database configuration module
    - Implement migration runner utility
    - _Requirements: 1.2, 1.3_

  - [x] 2.2 Create database schema migration

    - Write SQL migration for users table with organization_id, name, email, pin_hash, role, supervisor_topic_id, notification_enabled
    - Write SQL migration for organizations table with id (max 15 chars), name, owner_id
    - Write SQL migration for topics table with id (UUIDv7), organization_id, name
    - Write SQL migration for topic_memberships table
    - Write SQL migration for messages table with level, title, message, code, scope, topic_id
    - Write SQL migration for message_acknowledgements table
    - Write SQL migration for refresh_tokens table
    - Add all necessary indexes for performance
    - _Requirements: 1.1, 1.2, 2.1, 2.2, 5.1, 7.1, 11.5_

- [x] 3. Implement backend core utilities and middleware

  - [x] 3.1 Create ID generation utility

    - Implement UUIDv7 generator function
    - Implement PIN generator (unique within organization)
    - _Requirements: 2.2, 2.4_

  - [x] 3.2 Create authentication utilities

    - Implement sha-256 hashing for PINs
    - Implement JWT token generation and verification (15-minute expiration for access tokens)
    - Implement refresh token generation and storage
    - _Requirements: 9.1, 9.2_

  - [x] 3.3 Create authentication middleware

    - Implement JWT verification middleware for protected routes
    - Extract user information from token and attach to request context
    - Handle token expiration errors
    - _Requirements: 9.2, 9.3_

  - [x] 3.4 Create authorization middleware

    - Implement role-based permission checking (Owner, Admin, Supervisor, Normal)
    - Implement organization membership verification
    - Implement topic permission verification for Supervisors
    - _Requirements: 3.1, 3.2, 4.1, 5.1.1, 7.1, 8.1_

  - [x] 3.5 Update existing middleware to use standardized API response format




    - Update auth middleware error responses to use `{status: false, message: string, data: {code: string}}` format
    - Update authorization middleware error responses to use standardized format
    - Update corresponding middleware tests to expect new response format
    - _Requirements: All API requirements_

- [x] 4. Implement authentication service and endpoints





  - [x] 4.1 Create authentication service



    - Implement login function (validate PIN + Organization ID, return access and refresh tokens)
    - Implement refresh token function (validate refresh token, issue new tokens)
    - Implement logout function (invalidate refresh token)
    - _Requirements: 9.1, 9.2, 9.4_

  - [x] 4.2 Create authentication API endpoints


    - Implement POST /api/auth/login endpoint
    - Implement POST /api/auth/refresh endpoint
    - Implement POST /api/auth/logout endpoint
    - Add request validation and error handling
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [ ] 5. Implement organization service and endpoints

  - [ ] 5.1 Create organization service

    - Implement create organization function (validate org ID length, check uniqueness, create owner user)
    - Implement register user function (generate PIN, create user with role)
    - Implement promote user to Admin function (Owner only)
    - Implement demote Admin to Normal User function (Owner only)
    - Implement transfer ownership function (Owner to Admin)
    - Implement kick user function (remove user from organization)
    - _Requirements: 1.1, 1.2, 1.4, 2.1, 2.2, 2.3, 3.1, 3.1.1, 3.1.2, 3.2.1, 3.2.2, 4.1, 4.2_

  - [ ] 5.2 Create organization API endpoints
    - Implement POST /api/organizations endpoint (create organization)
    - Implement POST /api/organizations/:orgId/users endpoint (register user)
    - Implement PUT /api/organizations/:orgId/users/:userId/role endpoint (promote/demote)
    - Implement PUT /api/organizations/:orgId/ownership endpoint (transfer ownership)
    - Implement DELETE /api/organizations/:orgId/users/:userId endpoint (kick user)
    - Add authorization checks and error handling
    - _Requirements: 1.1, 1.4, 2.1, 2.4, 3.1, 3.2, 4.1, 4.4_

- [ ] 6. Implement topic service and endpoints

  - [ ] 6.1 Create topic service

    - Implement create topic function
    - Implement assign user to topic function
    - Implement promote user to Supervisor for topic function (set supervisor_topic_id)
    - Implement demote Supervisor to Normal User function (clear supervisor_topic_id)
    - Implement get topics for organization function
    - _Requirements: 5.1, 5.2, 5.1.1, 5.1.4, 5.2.1, 6.1, 6.2_

  - [ ] 6.2 Create topic API endpoints
    - Implement POST /api/organizations/:orgId/topics endpoint (create topic)
    - Implement POST /api/organizations/:orgId/topics/:topicId/users endpoint (assign user to topic)
    - Implement GET /api/organizations/:orgId/topics endpoint (list topics)
    - Add authorization checks (Admin/Owner only)
    - _Requirements: 5.1, 5.2, 6.1, 6.2, 6.3_

- [ ] 7. Implement WebSocket server infrastructure

  - [ ] 7.1 Set up WebSocket server

    - Install WebSocket library (ws or uWebSockets.js)
    - Create WebSocket server instance
    - Implement connection authentication using JWT
    - Implement connection lifecycle management (connect, disconnect, reconnect)
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

  - [ ] 7.2 Implement connection mapping
    - Create user ID to WebSocket connection mapping
    - Handle multiple connections per user (multiple devices)
    - Implement heartbeat/ping-pong for connection health
    - Clean up disconnected connections
    - _Requirements: 10.1, 10.4_

- [ ] 8. Implement broadcast service and endpoints

  - [ ] 8.1 Create broadcast service

    - Implement broadcast message function (validate permissions, determine recipients)
    - Implement recipient resolution logic (organization-wide vs topic-scoped)
    - Implement Supervisor permission logic (auto-use assigned topic)
    - Implement message delivery via WebSocket connections
    - Implement message acknowledgement function
    - Implement message history retrieval function
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 8.1, 8.2, 8.3, 8.4, 8.5, 11.1, 11.5_

  - [ ] 8.2 Create broadcast API endpoints

    - Implement POST /api/broadcast endpoint (create and send broadcast)
    - Implement POST /api/messages/:messageId/acknowledge endpoint
    - Implement GET /api/messages/history endpoint
    - Add role-based authorization (Owner/Admin/Supervisor)
    - Validate scope and topicId parameters based on user role
    - _Requirements: 7.1, 7.5, 8.1, 8.5, 11.1, 11.5_

  - [ ] 8.3 Implement WebSocket message events
    - Implement server-to-client 'message:broadcast' event
    - Implement client-to-server 'message:acknowledge' event handler
    - Add message payload validation
    - _Requirements: 10.1, 10.5, 11.1_

- [x] 9. Implement Flutter frontend authentication module

  - [x] 9.1 Set up Flutter project dependencies

    - Add http package for REST API calls
    - Add web_socket_channel for WebSocket connection
    - Add flutter_secure_storage for token storage
    - Add provider or riverpod for state management
    - _Requirements: 9.1, 9.4, 10.1_

  - [x] 9.2 Create authentication service

    - Implement login function (call POST /api/auth/login)
    - Implement token storage (access token and refresh token)
    - Implement token refresh logic (automatic on 401 errors)
    - Implement logout function (call POST /api/auth/logout, clear tokens)
    - _Requirements: 9.1, 9.2, 9.4_

  - [x] 9.3 Create login screen UI
    - Create PIN input field
    - Create Organization ID input field
    - Create login button with loading state
    - Display error messages for invalid credentials
    - Navigate to appropriate screen on successful login based on role
    - _Requirements: 9.1, 9.2, 9.3_

- [ ] 10. Implement Flutter frontend WebSocket client

  - [ ] 10.1 Create WebSocket service

    - Implement WebSocket connection with JWT authentication
    - Implement connection lifecycle management (connect on login, disconnect on logout)
    - Implement reconnection logic on network recovery
    - Handle background/foreground transitions
    - _Requirements: 10.1, 10.2, 10.4_

  - [ ] 10.2 Implement message event handlers
    - Parse incoming 'message:broadcast' events
    - Emit events to notification service
    - Send 'message:acknowledge' events to server
    - _Requirements: 10.1, 10.5, 11.1, 11.2_

- [ ] 11. Implement Flutter frontend notification service

  - [ ] 11.1 Set up notification dependencies

    - Add vibration package for haptic feedback
    - Add flutter_local_notifications for persistent notifications
    - Add audioplayers for sound playback
    - Configure platform-specific notification permissions
    - _Requirements: 10.1, 10.2, 10.3_

  - [ ] 11.2 Create notification service

    - Implement notification trigger based on severity level (low: vibrate, medium: vibrate + pulse, high: vibrate + pulse + sound)
    - Implement screen pulse effect using overlay widgets
    - Implement notification stop on acknowledgement
    - Check user's notification status preference before triggering
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 12.2, 12.5_

  - [ ] 11.3 Implement notification patterns
    - Create vibration pattern for low severity (single vibration)
    - Create vibration + screen pulse pattern for medium severity
    - Create vibration + screen pulse + sound pattern for high severity (continuous until acknowledged)
    - _Requirements: 10.1, 10.2, 10.3_

- [ ] 12. Implement Flutter frontend user screens (Normal User)

  - [ ] 12.1 Create message inbox screen

    - Display list of received broadcast messages
    - Show message level indicator (color-coded)
    - Show message title, timestamp, and acknowledgement status
    - Implement pull-to-refresh
    - _Requirements: 10.5, 11.5_

  - [ ] 12.2 Create message detail screen

    - Display full message content (title, message, code)
    - Display message level and timestamp
    - Show acknowledge button
    - Call acknowledgement API and stop notifications on button press
    - _Requirements: 10.5, 11.1, 11.2, 11.3, 11.4, 11.5_

  - [ ] 12.3 Create settings screen
    - Implement notification status toggle switch
    - Persist notification preference locally and to backend
    - Display user information (name, email, organization)
    - Add logout button
    - _Requirements: 12.1, 12.2, 12.3, 12.4_

- [ ] 13. Implement Flutter frontend admin/owner screens

  - [ ] 13.1 Create organization dashboard screen

    - Display organization information (ID, name)
    - Show user count and topic count
    - Navigation to user management, topic management, and broadcast screens
    - Show ownership transfer option (Owner only)
    - _Requirements: 1.3, 3.1, 3.2, 4.1, 5.1, 6.1_

  - [ ] 13.2 Create user management screen

    - Display list of users with name, email, role
    - Implement register new user form (name, email, role)
    - Display generated PIN after registration
    - Implement promote/demote user actions
    - Implement kick user action
    - Add role-based UI (Owner can promote/demote Admins, Admin cannot)
    - _Requirements: 2.1, 2.2, 2.4, 3.1, 3.2, 4.1, 4.2, 4.4_

  - [ ] 13.3 Create topic management screen

    - Display list of topics with name and supervisor count
    - Implement create topic form
    - Implement assign user to topic action
    - Implement promote user to Supervisor for topic action
    - Implement demote Supervisor action
    - _Requirements: 5.1, 5.2, 5.1.1, 5.1.4, 5.2.1, 6.1, 6.2_

  - [ ] 13.4 Create broadcast composer screen

    - Implement severity level selector (low, medium, high)
    - Implement scope selector (organization-wide or topic) - Admin/Owner only
    - Implement topic selector (if scope is topic) - Admin/Owner only
    - Create title input field
    - Create message text input field
    - Create optional code input field
    - Implement send button with loading state
    - Show success/error feedback
    - For Supervisors: auto-set scope to topic and use assigned topic
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 8.1, 8.2, 8.3, 8.4_

  - [ ] 13.5 Create ownership transfer screen (Owner only)
    - Display list of current Admins
    - Implement transfer ownership action with confirmation dialog
    - Show warning that current Owner will become Admin
    - _Requirements: 3.2.1, 3.2.2, 3.2.3, 3.2.4_

- [ ] 14. Implement Flutter frontend supervisor screens

  - [ ] 14.1 Create supervisor dashboard screen

    - Display assigned topic information
    - Show topic member count
    - Navigation to broadcast composer (topic-scoped only)
    - _Requirements: 8.1, 8.4, 8.5_

  - [ ] 14.2 Adapt broadcast composer for Supervisor
    - Remove scope selector (always topic)
    - Remove topic selector (use assigned topic)
    - Keep severity level, title, message, code inputs
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [ ] 15. Implement error handling and validation

  - [ ] 15.1 Add backend input validation

    - Validate organization ID length (max 15 characters)
    - Validate email format
    - Validate required fields on all endpoints
    - Return appropriate error codes and messages
    - _Requirements: 1.1, 1.4, 2.1, 7.1_

  - [ ] 15.2 Add frontend error handling
    - Display user-friendly error messages for API failures
    - Implement retry mechanism for failed requests
    - Show offline indicator when WebSocket disconnects
    - Handle session expiration (redirect to login)
    - _Requirements: 9.3, 10.4_

- [ ] 16. Create organization creation flow

  - [ ] 16.1 Create organization registration screen
    - Create organization ID input field (max 15 characters)
    - Create organization name input field
    - Create owner name input field
    - Create owner email input field
    - Implement create button with validation
    - Display generated owner PIN after creation
    - Provide option to copy PIN
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ] 17. Implement backend API server setup

  - [ ] 17.1 Create main server file

    - Set up Bun HTTP server
    - Configure CORS for Flutter app
    - Set up request logging middleware
    - Set up error handling middleware
    - Mount all API routes
    - Start WebSocket server
    - _Requirements: All backend requirements_

  - [ ] 17.2 Create environment configuration
    - Create .env file template
    - Configure database connection string
    - Configure JWT secret
    - Configure server port
    - Configure token expiration times
    - _Requirements: All backend requirements_

- [ ] 18. Implement frontend routing and navigation

  - [ ] 18.1 Set up Flutter navigation

    - Configure go_router or similar routing package
    - Define routes for all screens
    - Implement authentication guard (redirect to login if not authenticated)
    - Implement role-based routing (different home screens for Owner/Admin/Supervisor/Normal)
    - _Requirements: 9.1, 9.2_

  - [ ] 18.2 Create main app structure
    - Create app entry point with MaterialApp
    - Set up theme configuration
    - Initialize services (auth, WebSocket, notifications)
    - Handle app lifecycle (foreground/background)
    - _Requirements: All frontend requirements_

- [ ]\* 19. Add backend API documentation

  - Create OpenAPI/Swagger documentation for all endpoints
  - Document request/response schemas
  - Document authentication requirements
  - Document error codes
  - _Requirements: All API requirements_

- [ ]\* 20. Add logging and monitoring
  - Implement structured logging in backend
  - Add request/response logging
  - Add error logging with stack traces
  - Add WebSocket connection logging
  - _Requirements: All requirements_
