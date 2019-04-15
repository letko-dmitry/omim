// Wraps framework access
#pragma once

#import "map/framework.hpp"

/// Creates framework at first access
Framework & GetFramework();
/// Releases framework resources
void DeleteFramework();
