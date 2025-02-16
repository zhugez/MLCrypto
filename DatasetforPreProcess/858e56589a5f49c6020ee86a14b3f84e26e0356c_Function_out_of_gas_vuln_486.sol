pragma solidity ^0.4.23;


contract Functions {

    bytes32[] public randomHashes;

    function fillWithHashes() public {
        require(randomHashes.length == 0);

        for (uint i = block.number - 100; i < block.number; i++) {
            randomHashes.push(blockhash(i));
        }
    }

    
    
    
    
    function calculateSeed(uint[] _randomHashIds, uint _timestamp) public view returns (uint) {
        require(_timestamp != 0);
        require(_randomHashIds.length == 10);

        bytes32 randomSeed = keccak256(
            abi.encodePacked(
            randomHashes[_randomHashIds[0]], randomHashes[_randomHashIds[1]],
            randomHashes[_randomHashIds[2]], randomHashes[_randomHashIds[3]],
            randomHashes[_randomHashIds[4]], randomHashes[_randomHashIds[5]],
            randomHashes[_randomHashIds[6]], randomHashes[_randomHashIds[7]],
            randomHashes[_randomHashIds[8]], randomHashes[_randomHashIds[9]],
            _timestamp
            )
        );

        return uint(randomSeed);
    }

    function getRandomHashesLength() public view returns(uint) {
        return randomHashes.length;
    }

    
    
    
    function decodeAssets(bytes32[] _potentialAssets) public pure returns (uint[] assets) {
        require(_potentialAssets.length > 0);

        uint[] memory assetsCopy = new uint[](_potentialAssets.length*10);
        uint numberOfAssets = 0;

    function nestedLoops(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                
            }
        }
    }
    

        for (uint j = 0; j < _potentialAssets.length; j++) {
            uint input;
            bytes32 pot = _potentialAssets[j];

            assembly {
                input := pot
            }

            for (uint i = 10; i > 0; i--) {
                uint mask = (2 << ((i-1) * 24)) / 2;
                uint b = (input & (mask * 16777215)) / mask;

                if (b != 0) {
                    assetsCopy[numberOfAssets] = b;
                    numberOfAssets++;
                }

    function nestedLoops(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                
            }
        }
    }
    
            }
        }

        assets = new uint[](numberOfAssets);
        for (i = 0; i < numberOfAssets; i++) {
            assets[i] = assetsCopy[i];
        }
    }

    
    
    
    
    function pickRandomAssets(uint _finalSeed, bytes32[] _potentialAssets) public pure returns(uint[] finalPicked) {
        require(_finalSeed != 0);
        require(_potentialAssets.length > 0);

        uint[] memory assetIds = decodeAssets(_potentialAssets);
        uint[] memory pickedIds = new uint[](assetIds.length);

        uint finalSeedCopy = _finalSeed;
        uint index = 0;

        for (uint i = 0; i < assetIds.length; i++) {
            finalSeedCopy = uint(keccak256(abi.encodePacked(finalSeedCopy, assetIds[i])));
            if (finalSeedCopy % 2 == 0) {
                pickedIds[index] = assetIds[i];
                index++;
            }
        }

        finalPicked = new uint[](index);
        for (i = 0; i < index; i++) {
            finalPicked[i] = pickedIds[i];
        }
    }

    
    
    
    
    
    
    function getImage(uint _finalSeed, bytes32[] _potentialAssets, uint _width, uint _height) public pure 
    returns(uint[] finalPicked, uint[] x, uint[] y, uint[] zoom, uint[] rotation, uint[] layers) {
        require(_finalSeed != 0);
        require(_potentialAssets.length > 0);

        uint[] memory assetIds = decodeAssets(_potentialAssets);
        uint[] memory pickedIds = new uint[](assetIds.length);
        x = new uint[](assetIds.length);
        y = new uint[](assetIds.length);
        zoom = new uint[](assetIds.length);
        rotation = new uint[](assetIds.length);
        layers = new uint[](assetIds.length);

        uint finalSeedCopy = _finalSeed;
        uint index = 0;

        for (uint i = 0; i < assetIds.length; i++) {
            finalSeedCopy = uint(keccak256(abi.encodePacked(finalSeedCopy, assetIds[i])));
            if (finalSeedCopy % 2 == 0) {
                pickedIds[index] = assetIds[i];
                (x[index], y[index], zoom[index], rotation[index], layers[index]) = pickRandomAssetPosition(finalSeedCopy, _width, _height);
                index++;
            }
        }

        finalPicked = new uint[](index);
        for (i = 0; i < index; i++) {
            finalPicked[i] = pickedIds[i];
        }
    }

    
    
    
    
    
    function pickRandomAssetPosition(uint _randomSeed, uint _width, uint _height) public pure 
    returns (uint x, uint y, uint zoom, uint rotation, uint layer) {
        
        x = _randomSeed % _width;
        y = _randomSeed % _height;
        zoom = _randomSeed % 200 + 800;
        rotation = _randomSeed % 360;
        
        
        layer = _randomSeed % 1234567; 
    }

    
    
    
    
    function getFinalSeed(uint _randomSeed, uint _iterations) public pure returns (bytes32) {
        require(_randomSeed != 0);
        require(_iterations != 0);
        bytes32 finalSeed = bytes32(_randomSeed);

        finalSeed = keccak256(abi.encodePacked(_randomSeed, _iterations));
        for (uint i = 0; i < _iterations; i++) {
            finalSeed = keccak256(abi.encodePacked(finalSeed, i));
        }

        return finalSeed;
    }

    function toHex(uint _randomSeed) public pure returns (bytes32) {
        return bytes32(_randomSeed);
    }
}