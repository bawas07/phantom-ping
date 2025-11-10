# Requirements Document

## Introduction

Phantom Ping is a group pager application that enables administrators to broadcast important messages to users within their organization with three severity levels (low, medium, high). The system operates on a mesh network model where each organization is independent, and users receive notifications based on their organization membership. The application follows a monorepo structure with a Flutter frontend and Bun backend.

## Glossary

- **Phantom Ping System**: The complete group pager application including frontend and backend components
- **Owner**: The highest privilege role in an organization with exclusive rights to promote/demote Admins and transfer ownership
- **Admin**: A user role with privileges to register users, promote/demote Supervisors, kick users, manage topics, and broadcast messages organization-wide (mutually exclusive with Supervisor role)
- **Supervisor**: A user role with privileges to broadcast messages within their assigned topic only (mutually exclusive with Admin role)
- **Normal User**: A user role that can only receive and acknowledge broadcast messages
- **Organization**: An independent mesh network created by an Owner, identified by a unique Organization ID, containing minimal data structure
- **Topic**: A sub-mesh within an organization that groups users for targeted messaging
- **PIN**: A unique numeric identifier assigned to each user within their organization for authentication
- **Broadcast Message**: A message sent by an Owner, Admin, or Supervisor containing level, title, message text, and optional code
- **Severity Level**: The urgency classification of a message (low, medium, or high)
- **Acknowledgement**: A user action that stops the broadcast message from appearing or vibrating
- **Notification Status**: A user preference to enable or disable receiving notifications

## Requirements

### Requirement 1

**User Story:** As an Owner, I want to create my own organization with minimal data, so that I can manage a separate group of users with independent messaging

#### Acceptance Criteria

1. WHEN an Owner initiates organization creation, THE Phantom Ping System SHALL generate a unique Organization ID
2. THE Phantom Ping System SHALL store the organization with minimal data structure (Organization ID and Owner reference)
3. THE Phantom Ping System SHALL assign the creator as the Owner of the organization
4. THE Phantom Ping System SHALL allow the Owner to access the organization management panel after creation
5. THE Phantom Ping System SHALL prevent duplicate Organization IDs across all organizations

### Requirement 2

**User Story:** As an Admin, I want to register users in my organization using unique PINs, so that users can securely access the pager system

#### Acceptance Criteria

1. WHEN an Admin registers a new user, THE Phantom Ping System SHALL generate a unique PIN for that user within the organization
2. THE Phantom Ping System SHALL ensure the PIN is unique only within the specific organization scope
3. THE Phantom Ping System SHALL store the user registration with the associated Organization ID and PIN
4. THE Phantom Ping System SHALL provide the PIN to the Admin for distribution to the user
5. THE Phantom Ping System SHALL allow PINs to be reused across different organizations

### Requirement 3

**User Story:** As an Owner, I want to promote Normal Users to Admin role, so that I can share organization management responsibilities

#### Acceptance Criteria

1. WHEN an Owner selects a Normal User for promotion to Admin, THE Phantom Ping System SHALL change the user's role to Admin
2. THE Phantom Ping System SHALL grant the promoted user all Admin privileges within the organization
3. THE Phantom Ping System SHALL allow multiple Admins to exist within a single organization
4. THE Phantom Ping System SHALL prevent a user from being both Admin and Supervisor simultaneously
5. THE Phantom Ping System SHALL persist the role change across sessions

### Requirement 3.1

**User Story:** As an Owner, I want to demote Admins to Normal User role, so that I can revoke management privileges when needed

#### Acceptance Criteria

1. WHEN an Owner demotes an Admin, THE Phantom Ping System SHALL change the user's role to Normal User
2. THE Phantom Ping System SHALL revoke all Admin privileges from the demoted user
3. THE Phantom Ping System SHALL prevent Admins from demoting other Admins
4. THE Phantom Ping System SHALL allow only the Owner to demote Admins

### Requirement 3.2

**User Story:** As an Owner, I want to transfer ownership to another Admin, so that I can delegate ultimate control of the organization

#### Acceptance Criteria

1. WHEN an Owner transfers ownership to an Admin, THE Phantom Ping System SHALL change the target Admin's role to Owner
2. WHEN an Owner transfers ownership, THE Phantom Ping System SHALL change the current Owner's role to Admin
3. THE Phantom Ping System SHALL ensure only one Owner exists per organization at any time
4. THE Phantom Ping System SHALL allow ownership transfer only to existing Admins
5. THE Phantom Ping System SHALL persist the ownership change across sessions

### Requirement 4

**User Story:** As an Admin, I want to remove users from my organization, so that I can manage membership and revoke access when needed

#### Acceptance Criteria

1. WHEN an Admin kicks a user from the organization, THE Phantom Ping System SHALL remove the user's access to the organization
2. WHEN an Admin kicks a user, THE Phantom Ping System SHALL invalidate the user's PIN for that organization
3. THE Phantom Ping System SHALL prevent the kicked user from receiving further broadcast messages from the organization
4. THE Phantom Ping System SHALL allow the Admin to kick any user including other Admins and Supervisors

### Requirement 5

**User Story:** As an Admin, I want to create topics within my organization, so that I can organize users into sub-groups for targeted messaging

#### Acceptance Criteria

1. WHEN an Admin creates a topic, THE Phantom Ping System SHALL generate a unique topic identifier within the organization
2. THE Phantom Ping System SHALL store the topic as a sub-mesh within the organization
3. THE Phantom Ping System SHALL allow multiple topics to exist within a single organization
4. THE Phantom Ping System SHALL allow topics to have zero or more Supervisors assigned

### Requirement 5.1

**User Story:** As an Admin, I want to promote Normal Users to Supervisor role for specific topics, so that I can delegate topic-level messaging responsibilities

#### Acceptance Criteria

1. WHEN an Admin promotes a Normal User to Supervisor for a topic, THE Phantom Ping System SHALL assign the Supervisor role to that user for the specified topic
2. THE Phantom Ping System SHALL allow a topic to have multiple Supervisors
3. THE Phantom Ping System SHALL prevent a user from being both Admin and Supervisor simultaneously
4. THE Phantom Ping System SHALL bind each Supervisor to exactly one topic
5. THE Phantom Ping System SHALL persist the Supervisor assignment across sessions

### Requirement 5.2

**User Story:** As an Admin, I want to demote Supervisors to Normal User role, so that I can revoke topic-level messaging privileges when needed

#### Acceptance Criteria

1. WHEN an Admin demotes a Supervisor, THE Phantom Ping System SHALL remove the Supervisor role from the user
2. THE Phantom Ping System SHALL revoke the user's broadcast privileges
3. THE Phantom Ping System SHALL remove the topic assignment from the user
4. THE Phantom Ping System SHALL change the user's role to Normal User

### Requirement 6

**User Story:** As an Admin, I want to assign users to topics, so that they receive targeted messages relevant to their sub-group

#### Acceptance Criteria

1. WHEN an Admin assigns a user to a topic, THE Phantom Ping System SHALL add the user to the topic membership
2. THE Phantom Ping System SHALL allow a user to be assigned to multiple topics within the organization
3. THE Phantom Ping System SHALL allow a user to exist in the organization without being assigned to any topic
4. THE Phantom Ping System SHALL persist topic assignments across sessions

### Requirement 7

**User Story:** As an Owner or Admin, I want to broadcast messages organization-wide or to specific topics, so that I can communicate with the appropriate audience

#### Acceptance Criteria

1. WHEN an Owner or Admin creates a broadcast message, THE Phantom Ping System SHALL require a severity level (low, medium, or high)
2. WHEN an Owner or Admin creates a broadcast message, THE Phantom Ping System SHALL require a title and message text
3. WHEN an Owner or Admin creates a broadcast message, THE Phantom Ping System SHALL accept an optional code field
4. WHEN an Owner or Admin broadcasts organization-wide, THE Phantom Ping System SHALL deliver the message to all users in the organization
5. WHEN an Owner or Admin broadcasts to a specific topic, THE Phantom Ping System SHALL deliver the message only to users assigned to that topic
6. THE Phantom Ping System SHALL include all message fields (level, title, message, code) in the broadcast payload

### Requirement 8

**User Story:** As a Supervisor, I want to broadcast messages within my assigned topic, so that I can communicate with my sub-group without Admin privileges

#### Acceptance Criteria

1. WHEN a Supervisor creates a broadcast message, THE Phantom Ping System SHALL require a severity level (low, medium, or high)
2. WHEN a Supervisor creates a broadcast message, THE Phantom Ping System SHALL require a title and message text
3. WHEN a Supervisor creates a broadcast message, THE Phantom Ping System SHALL accept an optional code field
4. WHEN a Supervisor submits a broadcast message, THE Phantom Ping System SHALL deliver the message only to users in the Supervisor's assigned topic
5. THE Phantom Ping System SHALL prevent Supervisors from broadcasting to other topics or organization-wide

### Requirement 9

**User Story:** As a Normal User, I want to login using my PIN and Organization ID, so that I can access messages for my organization

#### Acceptance Criteria

1. WHEN a Normal User provides a PIN and Organization ID, THE Phantom Ping System SHALL verify the credentials match a registered user
2. IF the credentials are valid, THEN THE Phantom Ping System SHALL grant access to the user's pager interface
3. IF the credentials are invalid, THEN THE Phantom Ping System SHALL deny access and display an error message
4. THE Phantom Ping System SHALL maintain the user's authenticated session after successful login

### Requirement 10

**User Story:** As a Normal User, I want to receive broadcast messages with appropriate notifications based on severity level, so that I am alerted according to message urgency

#### Acceptance Criteria

1. WHEN a broadcast message with low severity is received, THE Phantom Ping System SHALL trigger device vibration only
2. WHEN a broadcast message with medium severity is received, THE Phantom Ping System SHALL trigger device vibration and screen pulse
3. WHEN a broadcast message with high severity is received, THE Phantom Ping System SHALL trigger device vibration, screen pulse, and sound
4. WHILE the user has notification status disabled, THE Phantom Ping System SHALL not trigger any notification alerts
5. THE Phantom Ping System SHALL display the message content (title, message, code) on the user's device

### Requirement 11

**User Story:** As a Normal User, I want to acknowledge received messages, so that I can stop the notification alerts and confirm I have seen the message

#### Acceptance Criteria

1. WHEN a Normal User performs an acknowledgement action on a broadcast message, THE Phantom Ping System SHALL stop all active notifications for that message
2. WHEN a Normal User performs an acknowledgement action, THE Phantom Ping System SHALL stop device vibration for the message
3. WHEN a Normal User performs an acknowledgement action, THE Phantom Ping System SHALL stop screen pulse for the message
4. WHEN a Normal User performs an acknowledgement action, THE Phantom Ping System SHALL stop sound playback for the message
5. THE Phantom Ping System SHALL record the acknowledgement status for the user and message

### Requirement 12

**User Story:** As a Normal User, I want to enable or disable my notification status, so that I can control when I receive pager alerts

#### Acceptance Criteria

1. THE Phantom Ping System SHALL provide a notification status toggle in the user interface
2. WHEN a Normal User disables notification status, THE Phantom Ping System SHALL suppress all notification alerts for subsequent broadcasts
3. WHEN a Normal User enables notification status, THE Phantom Ping System SHALL resume notification alerts for subsequent broadcasts
4. THE Phantom Ping System SHALL persist the user's notification status preference across sessions
5. WHILE notification status is disabled, THE Phantom Ping System SHALL still receive and store broadcast messages for later viewing

### Requirement 13

**User Story:** As a developer, I want the project structured as a monorepo with separate frontend and backend, so that the codebase is organized and maintainable

#### Acceptance Criteria

1. THE Phantom Ping System SHALL organize the codebase in a monorepo structure with root directory "phantom-ping"
2. THE Phantom Ping System SHALL contain a Flutter project in the "frontend" directory
3. THE Phantom Ping System SHALL contain a Bun project in the "backend" directory
4. THE Phantom Ping System SHALL contain Kiro documentation in the ".kiro" directory
5. THE Phantom Ping System SHALL maintain clear separation between frontend and backend concerns
