// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Canvas {
    uint16 public constant WIDTH = 5000;
    uint16 public constant HEIGHT = 5000;

    struct PixelInfo {
        address owner;
        uint256 expiry;
        uint24 color;
    }

    mapping(uint32 => PixelInfo) public pixels;

    function getPixel(uint16 x, uint16 y)
        public
        view
        returns (
            address owner,
            uint256 expiry,
            uint24 color
        )
    {
        uint32 coord = encodeCoord(x, y);
        
        PixelInfo storage pixel = pixels[coord];
        owner = pixel.owner;
        expiry = pixel.expiry;
        color = pixel.color;
    }

    event PixelSet(uint32 indexed coord, address owner, uint256 expiry, uint24 color);

    function setPixel(uint16 x, uint16 y, uint24 color) public {
        uint32 coord = encodeCoord(x, y);
        PixelInfo storage pixel = pixels[coord];

        if (pixel.expiry > block.timestamp && pixel.owner != msg.sender) {
            revert("Pixel is locked now");
        }

        uint256 expiry = block.timestamp + 10 minutes;
        pixel.color = color;
        pixel.owner = msg.sender;
        pixel.expiry = expiry;

        emit PixelSet(coord, msg.sender, expiry, color);
    }

    function setPixels(
        uint16[] memory xs,
        uint16[] memory ys,
        uint24[] memory colors
    ) public {
        require(
            xs.length == ys.length && xs.length == colors.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < xs.length; i++) {
            setPixel(xs[i], ys[i], colors[i]);
        }
    }

    function encodeCoord(uint16 x, uint16 y) public pure returns (uint32) {
        if (x >= WIDTH || y >= HEIGHT) {
            revert("Coordinates out of bounds");
        }
        return (uint32(x) << 16) | uint32(y);
    }

    function decodeCoord(uint32 encoded) public pure returns (uint16 x, uint16 y) {
        x = uint16(encoded >> 16);
        y = uint16(encoded & 0xFFFF);
        if (x >= WIDTH || y >= HEIGHT) {
            revert("Coordinates out of bounds");
        }
    }
}