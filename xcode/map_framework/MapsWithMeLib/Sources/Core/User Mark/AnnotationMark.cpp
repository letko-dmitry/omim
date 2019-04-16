//
//  AnnotationMark.cpp
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/15/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import "AnnotationMark.hpp"

AnnotationMark::AnnotationMark(m2::PointD const &ptOrg): UserMark(ptOrg, UserMark::Type::STATIC) {
    m_isSelected = false;
}

drape_ptr<df::UserPointMark::SymbolNameZoomInfo> AnnotationMark::GetSymbolNames() const {
    auto symbol = make_unique_dp<SymbolNameZoomInfo>();
    symbol->insert(std::make_pair(1 /* zoomLevel */, "coloredmark-default-s"));

    return symbol;
}

df::ColorConstant AnnotationMark::GetColorConstant() const {
    if (m_isSelected) {
        return "BookmarkRed";
    } else {
        return "BookmarkBlue";
    }
}

void AnnotationMark::SetSelected(bool isSelected) {
    if (m_isSelected != isSelected) {
        m_isSelected = isSelected;

        SetDirty();
    }
}
