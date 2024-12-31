# EtherEcho

EtherEcho is a decentralized digital time capsule platform built on the Stacks blockchain. It allows users to create, share, and discover digital "echoes" - time-locked content that can only be accessed after a specific blockchain height is reached.

## Features

- **Time-Locked Content**: Create digital echoes that remain sealed until a specific blockchain height
- **Multiple Content Types**: Support for text, photo, and audio content
- **Privacy Options**: Choose between public and whispered (private) echoes
- **Targeted Sharing**: Optionally specify a recipient for your echo
- **Social Interactions**: Amplify (like) and report content
- **Content Moderation**: Built-in reporting system and ability to silence inappropriate content
- **Random Discovery**: Find random unresonated echoes
- **User Statistics**: Track user engagement and interaction history

## Smart Contract Functions

### Core Functions

1. `create-echo`
   - Creates a new digital echo with specified content and parameters
   - Parameters:
     - `input-signature`: Content hash (string-ascii 256)
     - `input-title`: Echo title (string-ascii 64)
     - `input-essence`: Description (string-ascii 256)
     - `input-form`: Content type ("text", "photo", "audio")
     - `input-delay`: Time lock duration (in blocks)
     - `input-whispered`: Privacy flag (boolean)
     - `input-receiver`: Optional recipient (principal)
     - `input-harmonics`: Content tags (list of 5 string-ascii 32)

2. `resonate-echo`
   - Claim/open an echo after its time lock expires
   - Parameters:
     - `echo-id`: Unique identifier of the echo

3. `amplify-echo`
   - Like or appreciate an echo
   - Parameters:
     - `echo-id`: Unique identifier of the echo

### Administrative Functions

1. `toggle-waves-freeze`
   - Pause/unpause contract operations (admin only)

2. `silence-echo`
   - Remove inappropriate content (creator or admin only)
   - Parameters:
     - `echo-id`: Unique identifier of the echo

### Query Functions

1. `get-echo-details`
   - Retrieve echo details if unlocked
   - Parameters:
     - `echo-id`: Unique identifier of the echo

2. `get-resonator-stats`
   - Get user statistics
   - Parameters:
     - `resonator`: User principal

3. `get-total-echoes`
   - Get total number of echoes created

4. `is-echo-amplified-by-resonator`
   - Check if a user has amplified an echo
   - Parameters:
     - `echo-id`: Echo identifier
     - `resonator`: User principal

## Error Codes

- `u100`: Not master/unauthorized
- `u101`: Echo already resonated
- `u102`: Echo still time-locked
- `u103`: Invalid echo
- `u104`: Echo sealed
- `u105`: Invalid time lock duration
- `u106`: Invalid title length
- `u107`: Invalid description length
- `u108`: Invalid content type
- `u109`: Echo silenced
- `u110`: Self-amplification not allowed
- `u111`: Contract paused
- `u112`: Invalid tags
- `u113`: Invalid content hash
- `u114`: Invalid receiver
- `u115`: Invalid privacy flag

## Constants

- Maximum title length: 64 characters
- Maximum description length: 256 characters
- Minimum time lock: 1 block
- Maximum time lock: 52560 blocks
- Maximum tags per echo: 5
- Maximum tag length: 32 characters

## Security Features

- Input validation for all parameters
- Access control for administrative functions
- Time-lock enforcement
- Privacy controls
- Content moderation capabilities
- Protection against self-amplification
- Contract pause functionality

## Installation

1. Install Clarinet and its dependencies
2. Clone the repository
3. Deploy using Clarinet console or your preferred deployment method

## Testing

```bash
clarinet test
```

## Development

To start developing with EtherEcho:

1. Set up your development environment with Clarinet
2. Modify the contract in `contracts/etherecho.clar`
3. Run tests to ensure functionality
4. Deploy to testnet for testing
5. Deploy to mainnet when ready

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Support

For support and questions, please open an issue in the repository.