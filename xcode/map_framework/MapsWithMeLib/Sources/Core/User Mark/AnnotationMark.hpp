//
//  AnnotationMark.hpp
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/15/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#ifndef AnnotationUserMark_h
#define AnnotationUserMark_h

#import "map/user_mark.hpp"

class AnnotationMark final : public StaticMarkPoint {
public:
    explicit AnnotationMark(m2::PointD const &ptOrg);

    drape_ptr<SymbolNameZoomInfo> GetSymbolNames() const override;
    bool IsVisible() const override;

    void SetHidden(bool isHidden);
    void SetSymbol(std::string const & symbol);

private:
    std::string m_symbol;

    bool m_isHidden;
};

#endif /* AnnotationUserMark_h */
