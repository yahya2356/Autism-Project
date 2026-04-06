# Community Firestore Schema

## groups/{groupId}
- `groupName: string`
- `description: string`
- `category: string`
- `isPrivate: bool`
- `requiresApproval: bool`
- `ownerId: string`
- `createdBy: string` (legacy alias to owner)
- `createdAt: timestamp`
- `totalMembers: number`
- `locationCode: string` (fallback/legacy location rule)
- `allowedCountry: string?`
- `allowedCity: string?`
- `allowedLanguage: string?`
- `minChildAge: number?`
- `maxChildAge: number?`
- `allowedConditions: string[]`
- `instructions: string[]`
- `joinInstructions: string[]`

## groupMembers/{groupId_userId}
- `groupId: string`
- `userId: string`
- `role: string` (`owner` | `member`)
- `joinedAt: timestamp`

## groupJoinRequests/{groupId_userId}
- `groupId: string`
- `userId: string`
- `note: string`
- `status: string` (`pending` | `approved` | `rejected`)
- `createdAt: timestamp`
- `reviewedAt: timestamp?`
- `reviewedBy: string?`

## groupPosts/{postId}
- `groupId: string`
- `userId: string`
- `content: string`
- `timestamp: timestamp`
- `imageUrl: string?`
- `likeCount: number`
- `commentCount: number`
