--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import qualified Data.Char as Char
import           Control.Monad.ListM (sortByM)
import           Control.Monad (liftM2)
import           Data.Monoid (mappend, (<>))
import           Data.List (drop, unwords, groupBy)
import           System.FilePath (dropExtension, splitFileName)
import           Hakyll

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "js/**" $ do
        route   idRoute
        compile copyFileCompiler

    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "pages/**" $ version "menu" $ do
        compile $ getUnderlying >>= makeItem . toFilePath

    match "pages/**" $ do
        route $ setExtension "html"
        compile $ do
            ident <- getUnderlying
            page <- pandocCompiler

            let menuCtx = menuField $ fst (splitPath (toFilePath ident))

            renderedPage <- loadAndApplyTemplate  "templates/default.html"
                                                  (menuCtx <> defaultContext)
                                                  page
            relativizeUrls renderedPage

    match "index.html" $ do
        route idRoute
        compile $ do
            pages <- loadAll "pages/**"
            let indexCtx = listField "pages" defaultContext (return pages)
                        <> constField "title" "Home"
                        <> menuField "/"
                        <> defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler

--------------------------------------------------------------------------------

splitOn :: Char -> String -> [String]
splitOn _ [] = []
splitOn c xs = case dropWhile (== c) xs of
                     "" -> []
                     s  -> w : (splitOn c r)
                        where (w,r) = break (== c)  s

capitalize :: String -> String
capitalize [] = []
capitalize (x:xs) = Char.toUpper(x) : (map Char.toLower xs)

pathToHeading :: String -> String
pathToHeading = unwords . (map capitalize) . (splitOn '_')

splitPath :: String -> (String, String)
splitPath p = case splitOn '/' (drop 6 p) of
                  [parent, file] -> (parent, file)
                  _              -> error p

-- sortByM :: Monad m => (a -> a -> m Ordering) -> [a] -> m [a]
-- liftM2 :: Monad m => (a1 -> a2 -> r) -> m a1 -> m a2 -> m r
-- compare :: a -> a -> Ordering

sortByMetadata :: String -> [String] -> Compiler [String]
sortByMetadata m = sortByM (\ fp1 fp2 -> liftM2 compare (getMetadataField' (fromFilePath fp1) m)
                                                        (getMetadataField' (fromFilePath fp2) m))

menus :: Compiler [Item (String, [(String, String)])]
menus = (loadAll (fromVersion $ Just "menu"))      -- Compiler [Item FilePath]
    >>= return . (map itemBody)                    -- Compiler [FilePath]
    >>= sortByMetadata "order"                     -- Compiler [FilePath] (sorted by order)
    >>= (return . map (splitPath . dropExtension)) -- Compiler [(String, String)]
    >>= (return . accumulatePaths)                 -- Compiler [(String, [(String, String)]]
    >>= (\ xs -> sequence $ map makeItem xs)       -- Compiler [Item (String, [(String, String)]]

menuField :: String -> Context a
menuField path = listField "menus" (  field "path" (return . fst . itemBody)
                                   <> field "menu" (return . pathToHeading . fst . itemBody)
                                   <> boolField "inSection" ((== path) . fst . itemBody)
                                   <> listFieldWith "submenus"
                                                    (  field "path"    (return . fst . itemBody)
                                                    <> field "subpath" (return . snd . itemBody)
                                                    <> field "submenu" (return . pathToHeading . snd . itemBody)
                                                    )
                                                    (sequence . map makeItem . snd . itemBody)
                                   ) menus

accumulatePaths :: [(String, String)] -> [(String, [(String, String)])]
accumulatePaths xs = zip parent (map removeMainPage children)
    where children = groupBy (\ a b -> (fst a) == (fst b)) xs
          parent   = map (fst . head) children
          removeMainPage :: [(String, String)] -> [(String, String)]
          removeMainPage = filter (\ (a,b) -> a /= b)
