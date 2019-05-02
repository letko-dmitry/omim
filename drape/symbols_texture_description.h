//
//  symbols_texture_description.h
//  drape
//
//  Created by Dmitry Letko on 5/1/19.
//  Copyright © 2019 maps.me. All rights reserved.
//

#ifndef symbols_texture_description_h
#define symbols_texture_description_h

#include <string>

namespace dp {
    struct SymbolsTextureDescription {
        std::string name;
        std::string imageFilePath;
        std::string mapFilePath;
    };
}

#endif /* symbols_texture_description_h */
