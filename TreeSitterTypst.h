//
//  TreeSitterTypst.h
//  Serifian
//
//  Created by Riccardo Persello on 28/09/23.
//

#ifndef TreeSitterTypst_h
#define TreeSitterTypst_h

#ifdef __cplusplus
extern "C" {
#endif

typedef struct TSLanguage TSLanguage;

// Replace {language} with the name of the parser you are importing.
const TSLanguage *tree_sitter_typst(void);

#ifdef __cplusplus
}
#endif

#endif /* TreeSitterTypst_h */
