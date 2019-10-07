####################################
# data process for TCGA data
# include TIL, expression data, and clinical data


# path --------------------------------------------------------------------

basic_path <- "/home/huff/project"
TIL_path <- file.path(basic_path,"/data/TCGA/immune_infiltration/miao_TCAP_prediction")
TCGA_path <- file.path("/home/huff/data/TCGA/TCGA_data") # pancan33_expr.rds.gz
data_path <- file.path(basic_path,"TCGA_nomogram/data")


# load data ---------------------------------------------------------------

# gene list exlude TIL prediction markers
inhibit_cells <- c("Exhausted","iTreg","Neutrophil","Monocyte","nTreg","Tr1")
non_inhibit_TIL_markers <- readr::read_tsv(file.path(data_path,"markers_used_to_predict_TIL_miao_TCAP.txt")) %>%
  tidyr::gather(key="Cell_type",value="markers")%>%
  dplyr::filter(!is.na(markers)) %>%
  dplyr::filter(! Cell_type %in% inhibit_cells)

checkpoints_as_TILMarker <- readr::read_tsv(file.path(data_path,"ICPs_all_info_class.tsv")) %>%
  dplyr::filter(! symbol %in% non_inhibit_TIL_markers$markers)

checkpoints <- readr::read_tsv(file.path(data_path,"ICPs_all_info_class.tsv"))

# expression data
genelist_exp <- readr::read_rds(file.path(TCGA_path,"pancan33_expr.rds.gz")) %>%
  dplyr::mutate(exp_filter = purrr::map2(expr,cancer_types,.f=function(.x,.y){
    print(.y)
    .x %>%
      dplyr::filter(symbol %in% checkpoints$symbol)
  })) %>%
  dplyr::select(-expr) 

# TIL data
TIL <- readr::read_rds(file.path(TIL_path,"pancan33_immune_infiltration_by_TCAP.rds.gz")) %>%
  dplyr::ungroup() %>%
  dplyr::select(-names)

# clinical data
clinical_2018cell <- readr::read_rds(file.path("/home/huff/project/data/TCGA-survival-time/cell.2018.survival","TCGA_pancan_cancer_cell_survival_time.rds.gz"))
clinical_TCGA <- readr::read_rds(file.path("/home/huff/project/TCGA_survival/data","Pancan.Merge.clinical.rds.gz"))

clinical_2018cell %>%
  dplyr::mutate(PFS = purrr::map(data,.f=function(.x){
    .x %>%
      dplyr::select(bcr_patient_barcode, PFS, PFS.time) %>%
      dplyr::rename("barcode"="bcr_patient_barcode")
  })) %>%
  dplyr::select(-data) %>%
  dplyr::rename("cancer_types"="type") %>%
  dplyr::inner_join(clinical_TCGA,by="cancer_types") %>%
  dplyr::rename("OS_stage"="clinical_data")-> clinical