/**
 * File              : DefaultCuts.C
 * Author            : Anton Riedel <anton.riedel@tum.de>
 * Date              : 06.10.2021
 * Last Modified Date: 06.10.2021
 * Last Modified By  : Anton Riedel <anton.riedel@tum.de>
 */

Int_t DefaultCuts(AliAnalysisTaskAR *task, Int_t centerMin, Int_t centerMax) {

  // set limits for control histograms and cuts
  // track variables
  // transverse momentum
  Double_t pt_le = 0.0;
  Double_t pt_ue = 5.0;
  Int_t pt_bins = (pt_ue - pt_le) * 100;
  Double_t pt_min = 0.2;
  Double_t pt_max = pt_ue;
  // azimuthal angle
  Double_t phi_le = 0.0;
  Double_t phi_ue = TMath::TwoPi();
  Int_t phi_bins = 360.;
  Double_t phi_min = phi_le;
  Double_t phi_max = phi_ue;
  // pseudo rapidity
  Double_t eta_le = -1.;
  Double_t eta_ue = 1.;
  Int_t eta_bins = (eta_ue - eta_le) * 100;
  Double_t eta_min = -0.8;
  Double_t eta_max = 0.8;
  // charge
  Double_t charge_le = -2.5;
  Double_t charge_ue = 2.5;
  Int_t charge_bins = (charge_ue - charge_le) * 1;
  Double_t charge_min = charge_le;
  Double_t charge_max = charge_ue;
  // number of clusters in the TPC
  Double_t tpcncls_le = 60.;
  Double_t tpcncls_ue = 160.;
  Int_t tpcncls_bins = tpcncls_ue - tpcncls_le;
  Double_t tpcncls_min = 70.;
  Double_t tpcncls_max = 159.;
  // number of crossed rows in the tpc
  // ONLY use tpcncls OR tpccrossed rows, NOT both
  Double_t tpccrossedrows_le = 60.;
  Double_t tpccrossedrows_ue = 160.;
  Int_t tpccrossedrows_bins = tpccrossedrows_ue - tpccrossedrows_le;
  Double_t tpccrossedrows_min = 70.;
  Double_t tpccrossedrows_max = 159.;
  // number of shared veteces
  Double_t tpcnclsfractionshared_le = 0.;
  Double_t tpcnclsfractionshared_ue = 1.;
  Int_t tpcnclsfractionshared_bins =
      (tpcnclsfractionshared_ue - tpcnclsfractionshared_le) * 100;
  Double_t tpcnclsfractionshared_min = 0.;
  Double_t tpcnclsfractionshared_max = 0.4; // cut only on upper limit
  // chi2 per ndf of tpc tracks
  Double_t tpcchi2perndf_le = 0.;
  Double_t tpcchi2perndf_ue = 5.0;
  Int_t tpcchi2perndf_bins = (tpcchi2perndf_ue - tpcchi2perndf_le) * 100;
  Double_t tpcchi2perndf_min = 0.1;
  Double_t tpcchi2perndf_max = 4.5;
  // number of clusters in the ITS
  Double_t itsncls_le = 0.;
  Double_t itsncls_ue = 10.;
  Int_t itsncls_bins = itsncls_ue - itsncls_le;
  Double_t itsncls_min = itsncls_le;
  Double_t itsncls_max = itsncls_ue;
  // chi2/NDF of the track fit
  Double_t chi2perndf_le = 0.;
  Double_t chi2perndf_ue = 5.0;
  Int_t chi2perndf_bins = (chi2perndf_ue - chi2perndf_le) * 100;
  Double_t chi2perndf_min = 0.9;
  Double_t chi2perndf_max = 4.5;
  // distance of closest approach in Z direction
  Double_t dcaz_le = -3.5;
  Double_t dcaz_ue = 3.5;
  Int_t dcaz_bins = (dcaz_ue - dcaz_le) * 100;
  Double_t dcaz_min = -3.2;
  Double_t dcaz_max = 3.2;
  // distance of closest approach in XY plane
  Double_t dcaxy_le = -2.5;
  Double_t dcaxy_ue = 2.5;
  Int_t dcaxy_bins = (dcaxy_ue - dcaxy_le) * 100;
  Double_t dcaxy_min = -2.4;
  Double_t dcaxy_max = 2.4;

  // event variables
  // multiplicity, estimated by number of tracks per event
  Double_t mul_le = 0.;
  Double_t mul_ue = 12000.;
  Int_t mul_bins = (mul_ue - mul_le) / 12;
  Double_t mul_min = mul_le;
  Double_t mul_max = mul_ue;
  // multiplicity, estimated by number of tracks per event that survive
  // track cuts this is also the number of tracks we fill into qvector
  Double_t mulq_le = 0.;
  Double_t mulq_ue = 3000.;
  Int_t mulq_bins = (mulq_ue - mulq_le) / 3;
  Double_t mulq_min = 12.;
  Double_t mulq_max = mulq_ue;
  // multiplicity, estimated by sum of all paritcle weights
  Double_t mulw_le = 0.;
  Double_t mulw_ue = 3000.;
  Int_t mulw_bins = (mulw_ue - mulw_le) / 3;
  Double_t mulw_min = 12.;
  Double_t mulw_max = mulw_ue;
  // reference multiplicity from AODHeadter
  // reference multiplicity is set to -999 for MC
  Double_t mulref_le = 0;
  Double_t mulref_ue = 3000;
  Int_t mulref_bins = (mulref_ue - mulref_le) / 3;
  Double_t mulref_min = 12;
  Double_t mulref_max = mulref_ue;
  // multiplicity, estimated by number of contributor to primary vertex
  Double_t ncontrib_le = 2.;
  Double_t ncontrib_ue = 3000.;
  Int_t ncontrib_bins = (ncontrib_ue - ncontrib_le) / 3;
  Double_t ncontrib_min = 2.;
  Double_t ncontrib_max = ncontrib_ue;
  // centrality
  Double_t cen_ue = centerMax;
  Double_t cen_le = centerMin;
  Int_t cen_bins = (cen_ue - cen_le) * 1;
  Double_t cen_min = centerMin;
  Double_t cen_max = centerMax;
  // x coordinate of primary vertex
  Double_t x_le = -2.;
  Double_t x_ue = 2.;
  Int_t x_bins = (x_ue - x_le) * 100.;
  Double_t x_min = -1.;
  Double_t x_max = 1.;
  // y coordinate of primary vertey
  Double_t y_le = -2.;
  Double_t y_ue = 2.;
  Int_t y_bins = (y_ue - y_le) * 100.;
  Double_t y_min = -1.;
  Double_t y_max = 1.;
  // z coordinate of primary vertez
  Double_t z_le = -12.;
  Double_t z_ue = 12.;
  Int_t z_bins = (z_ue - z_le) * 100.;
  Double_t z_min = -10.;
  Double_t z_max = 10.;
  // distance of primary vertex from the origin
  Double_t pos_le = 0;
  Double_t pos_ue = 15.;
  Int_t pos_bins = (pos_ue - pos_le) * 100.;
  Double_t pos_min = 1e-6;
  Double_t pos_max = pos_ue;
  // correlation cut on centrality
  Double_t m_cencor = 1.0;
  Double_t t_cencor = 10;
  // correlation cut on multiplicity
  Double_t m_mulcor = 1.4;
  Double_t t_mulcor = 300;
  // filterbit
  Int_t filterbit = 128;

  // most setters expect enumerations as arguments
  // those enumerations are defined in AliAnalysisTaskAR.h

  // setters for track control histograms
  task->SetTrackControlHistogramBinning(kPT, pt_bins, pt_le, pt_ue);
  task->SetTrackControlHistogramBinning(kPHI, phi_bins, phi_le, phi_ue);
  task->SetTrackControlHistogramBinning(kETA, eta_bins, eta_le, eta_ue);
  task->SetTrackControlHistogramBinning(kCHARGE, charge_bins, charge_le,
                                        charge_ue);
  task->SetTrackControlHistogramBinning(kTPCNCLS, tpcncls_bins, tpcncls_le,
                                        tpcncls_ue);
  task->SetTrackControlHistogramBinning(kTPCCROSSEDROWS, tpccrossedrows_bins,
                                        tpccrossedrows_le, tpccrossedrows_ue);
  task->SetTrackControlHistogramBinning(
      kTPCNCLSFRACTIONSHARED, tpcnclsfractionshared_bins,
      tpcnclsfractionshared_le, tpcnclsfractionshared_ue);
  task->SetTrackControlHistogramBinning(kTPCCHI2PERNDF, tpcchi2perndf_bins,
                                        tpcchi2perndf_le, tpcchi2perndf_ue);
  task->SetTrackControlHistogramBinning(kITSNCLS, itsncls_bins, itsncls_le,
                                        itsncls_ue);
  task->SetTrackControlHistogramBinning(kCHI2PERNDF, chi2perndf_bins,
                                        chi2perndf_le, chi2perndf_ue);
  task->SetTrackControlHistogramBinning(kDCAZ, dcaz_bins, dcaz_le, dcaz_ue);
  task->SetTrackControlHistogramBinning(kDCAXY, dcaxy_bins, dcaxy_le, dcaxy_ue);
  // setters for event control histograms
  task->SetEventControlHistogramBinning(kMUL, mul_bins, mul_le, mul_ue);
  task->SetEventControlHistogramBinning(kMULQ, mulq_bins, mulq_le, mulq_ue);
  task->SetEventControlHistogramBinning(kMULW, mulw_bins, mulw_le, mulw_ue);
  task->SetEventControlHistogramBinning(kMULREF, mulref_bins, mulref_le,
                                        mulref_ue);
  task->SetEventControlHistogramBinning(kNCONTRIB, ncontrib_bins, ncontrib_le,
                                        ncontrib_ue);
  task->SetEventControlHistogramBinning(kCEN, cen_bins, cen_le, cen_ue);
  task->SetEventControlHistogramBinning(kX, x_bins, x_le, x_ue);
  task->SetEventControlHistogramBinning(kY, y_bins, y_le, y_ue);
  task->SetEventControlHistogramBinning(kZ, z_bins, z_le, z_ue);
  task->SetEventControlHistogramBinning(kVPOS, pos_bins, pos_le, pos_ue);

  task->SetFillQAHistograms(kFALSE);
  task->SetFillQACorHistogramsOnly(kTRUE);

  // setter for centrality correlation histograms
  for (int i = 0; i < LAST_ECENESTIMATORS; i++) {
    for (int j = i + 1; j < LAST_ECENESTIMATORS; j++) {
      task->SetCenCorQAHistogramBinning(i, cen_bins, cen_le, cen_ue, j,
                                        cen_bins, cen_le, cen_ue);
    }
  }
  // setter for multiplicity correlation histograms
  Double_t MulCorMM[kMulEstimators][2] = {
      {mul_le, mul_ue},       {mulq_le, mulq_ue},         {mulw_le, mulw_ue},
      {mulref_le, mulref_ue}, {ncontrib_le, ncontrib_ue},
  };
  Int_t MulCorBin[kMulEstimators] = {mul_bins, mulq_bins, mulw_bins,
                                     mulref_bins, ncontrib_bins};
  for (int i = 0; i < kMulEstimators; i++) {
    for (int j = i + 1; j < kMulEstimators; j++) {
      task->SetMulCorQAHistogramBinning(i, MulCorBin[i], MulCorMM[i][0],
                                        MulCorMM[i][1], j, MulCorBin[j],
                                        MulCorMM[j][0], MulCorMM[j][1]);
    }
  }

  // setters for track cuts
  task->SetTrackCuts(kPT, pt_min, pt_max);
  task->SetTrackCuts(kPHI, phi_min, phi_max);
  task->SetTrackCuts(kETA, eta_min, eta_max);
  task->SetTrackCuts(kCHARGE, charge_min, charge_max);
  task->SetTrackCuts(kTPCNCLS, tpcncls_min, tpcncls_max);
  // task->SetTrackCuts(kTPCcrossedrows, tpccrossedrows_min,
  // tpccrossedrows_max);
  task->SetTrackCuts(kTPCNCLSFRACTIONSHARED, tpcnclsfractionshared_min,
                     tpcnclsfractionshared_max);
  task->SetTrackCuts(kTPCCHI2PERNDF, tpcchi2perndf_min, tpcchi2perndf_max);
  task->SetTrackCuts(kITSNCLS, itsncls_min, itsncls_max);
  task->SetTrackCuts(kCHI2PERNDF, chi2perndf_min, chi2perndf_max);
  task->SetTrackCuts(kDCAZ, dcaz_min, dcaz_max);
  task->SetTrackCuts(kDCAXY, dcaxy_min, dcaxy_max);
  // setters for event cuts
  // task->SetEventCuts(kMUL, mul_min, mul_max);
  task->SetEventCuts(kMULQ, mulq_min, mulq_max);
  // task->SetEventCuts(kMULW, mulw_min, mulw_max);
  task->SetEventCuts(kMULREF, mulref_min, mulref_max);
  task->SetEventCuts(kNCONTRIB, ncontrib_min, ncontrib_max);
  task->SetEventCuts(kCEN, centerMin, centerMax);
  task->SetEventCuts(kX, x_min, x_max);
  task->SetEventCuts(kY, y_min, y_max);
  task->SetEventCuts(kZ, z_min, z_max);
  task->SetEventCuts(kVPOS, pos_min, pos_max);
  // correlation cuts
  task->SetCenCorCut(m_cencor, t_cencor);
  task->SetMulCorCut(m_mulcor, t_mulcor);
  // other cuts
  task->SetFilterbit(filterbit); // typical 1,92,128,256,768
  task->SetPrimaryOnlyCut(kTRUE);
  task->SetChargedOnlyCut(kTRUE);
  task->SetGlobalTracksOnlyCut(
      kFALSE); // DO NOT USE in combination with filterbit
  task->SetCentralityEstimator(kV0M); // choices: kV0M,kCL0,kCL1,kSPDTRACKLETS

  // fill control histograms and then bail out
  task->SetFillControlHistogramsOnly(kTRUE);

  return 0;
}
