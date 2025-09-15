# ExpressVPN Configuration

Place your ExpressVPN `.ovpn` configuration file in this directory.

## How to get your ExpressVPN config:

1. **Log in to ExpressVPN**: Go to [ExpressVPN Setup](https://www.expressvpn.com/setup#manual)
2. **Select Manual Configuration**: Choose "Manual Config" 
3. **Download OpenVPN config**: Download the `.ovpn` file for your preferred server location
4. **Save here**: Save the file as `config.ovpn` in this directory

## File structure:
```
ovpn/
├── README.md          # This file
└── config.ovpn        # Your ExpressVPN configuration (you need to add this)
```

## Example filename:
- `config.ovpn` (recommended)
- Or any `.ovpn` file (will be auto-detected)

## Security Note:
The `.ovpn` file contains certificates and keys. This directory is included in `.gitignore` to prevent accidentally committing sensitive data to version control.
