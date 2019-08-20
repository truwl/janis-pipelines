version development

import "manta.wdl" as M
import "strelka_somatic.wdl" as S
import "bcftoolsview.wdl" as B
import "SplitMultiAllele.wdl" as S2

workflow strelkaSomaticVariantCaller {
  input {
    File normalBam
    File normalBam_bai
    File tumorBam
    File tumorBam_bai
    File reference
    File reference_amb
    File reference_ann
    File reference_bwt
    File reference_pac
    File reference_sa
    File reference_fai
    File reference_dict
    File? intervals
    File? intervals_tbi
    Array[String]? filters
  }
  call M.manta as manta {
    input:
      bam_bai=normalBam_bai,
      bam=normalBam,
      reference_amb=reference_amb,
      reference_ann=reference_ann,
      reference_bwt=reference_bwt,
      reference_pac=reference_pac,
      reference_sa=reference_sa,
      reference_fai=reference_fai,
      reference_dict=reference_dict,
      reference=reference,
      tumorBam_bai=tumorBam_bai,
      tumorBam=tumorBam,
      callRegions_tbi=intervals_tbi,
      callRegions=intervals
  }
  call S.strelka_somatic as strelka {
    input:
      normalBam_bai=normalBam_bai,
      normalBam=normalBam,
      tumorBam_bai=tumorBam_bai,
      tumorBam=tumorBam,
      reference_amb=reference_amb,
      reference_ann=reference_ann,
      reference_bwt=reference_bwt,
      reference_pac=reference_pac,
      reference_sa=reference_sa,
      reference_fai=reference_fai,
      reference_dict=reference_dict,
      reference=reference,
      indelCandidates_tbi=manta.candidateSmallIndels_tbi,
      indelCandidates=manta.candidateSmallIndels,
      callRegions_tbi=intervals_tbi,
      callRegions=intervals
  }
  call B.bcftoolsview as bcf_view {
    input:
      file=strelka.snvs,
      applyFilters=select_first([filters, ["PASS"]])
  }
  call S2.SplitMultiAllele as splitMultiAllele {
    input:
      vcf=bcf_view.out,
      reference_amb=reference_amb,
      reference_ann=reference_ann,
      reference_bwt=reference_bwt,
      reference_pac=reference_pac,
      reference_sa=reference_sa,
      reference_fai=reference_fai,
      reference_dict=reference_dict,
      reference=reference
  }
  output {
    File diploid = manta.diploidSV
    File diploid_tbi = manta.diploidSV_tbi
    File variants = strelka.snvs
    File variants_tbi = strelka.snvs_tbi
    File out = splitMultiAllele.out
  }
}