/* Copyright 2020 The OpenXLA Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
==============================================================================*/

#ifndef LHLO_GPU_OPS_ENUMS
#define LHLO_GPU_OPS_ENUMS

include "mlir/IR/OpBase.td"
include "mlir/IR/EnumAttr.td"
include "mlir/IR/AttrTypeBase.td"

include "lhlo_gpu/IR/lhlo_gpu_ops_base.td"

def ActivationModeNone : I32EnumAttrCase<"None", 0>;
def ActivationModeSigmoid : I32EnumAttrCase<"Sigmoid", 1>;
def ActivationModeTanh : I32EnumAttrCase<"Tanh", 2>;
def ActivationModeRelu : I32EnumAttrCase<"Relu", 3>;
def ActivationModeRelu6 : I32EnumAttrCase<"Relu6", 4>;
def ActivationModeReluX : I32EnumAttrCase<"ReluX", 5>;
def ActivationModeBandPass : I32EnumAttrCase<"BandPass", 6>;
def ActivationModeElu: I32EnumAttrCase<"Elu", 7>;
def ActivationModeLeakyRelu: I32EnumAttrCase<"LeakyRelu", 8>;

def Activation: I32EnumAttr<"Activation",
    "Activation applied with fused convolution",
    [ActivationModeNone,  ActivationModeSigmoid, ActivationModeTanh,
     ActivationModeRelu, ActivationModeRelu6, ActivationModeReluX,
     ActivationModeBandPass, ActivationModeElu, ActivationModeLeakyRelu]> {
  let genSpecializedAttr = 0;
  let cppNamespace = "::mlir::lmhlo_gpu";
}

def ActivationAttr : EnumAttr<LmhloGpuDialect, Activation, "activation">;

def BoolParameter : AttrOrTypeParameter<"bool", ""> {
  let parser = "::mlir::lmhlo_gpu::parseBool($_parser)";
}

def I64ArrayParameter :
    AttrOrTypeParameter<"::llvm::ArrayRef<int64_t>", ""> {
  let allocator = [{$_dst = $_allocator.copyInto($_self);}];
  let cppStorageType = "::llvm::SmallVector<int64_t>";
  let parser = "::mlir::lmhlo_gpu::parseI64Array($_parser)";
  let printer = "$_printer << '[' << $_self << ']'";
}

def ConvolutionBackendConfigAttr : AttrDef<
  LmhloGpuDialect, "ConvolutionBackendConfig"> {
  let mnemonic = "convolution_backend_config";
  let parameters = (ins
   // These six fields are a TableGen transliteration of AlgorithmProto.
   "int64_t":$algorithm,
   BoolParameter:$tensor_ops_enabled,
   // The next two fields are aligned arrays of knob IDs and values to
   // represent the knob_id -> knob_value map.
   I64ArrayParameter:$knob_ids,
   I64ArrayParameter:$knob_values,
   BoolParameter:$is_cudnn_frontend,
   // If the convolution has CUDNN_TENSOR_NCHW_VECT_C layout (applicable to
   // int8 data type only), this flag denotes that the filter (and bias, if
   // present) are reordered using `cudnnReorderFilterAndBias`.
   BoolParameter:$is_cudnn_reordered_int8,
   "int64_t":$workspace_size,

   // The following 3 attributes describe the layout as an array of integers
   // that list the dimensions in minor-to-major order similar to XLA's layout
   // representation. operand_0_layout and operand_0_layout described the layout
   // of the first 2 operands of the convolution, and result_layout describes
   // the layout of the primary output operand of the convolution.
   // Note: Not using names like input_layout or filter_layout as `input` may be
   // an input operand (for ConvForward) but output for ConvBackward.
   I64ArrayParameter:$operand_0_layout,
   I64ArrayParameter:$operand_1_layout,
   I64ArrayParameter:$result_layout
 );
  let assemblyFormat = "`<` struct(params) `>`";
 let summary = "GPU Convolution backend configuration";
}

def CublasLtMatmulEpilogueDefault : I32EnumAttrCase<"Default", 0>;
def CublasLtMatmulEpilogueBias : I32EnumAttrCase<"Bias", 1>;
def CublasLtMatmulEpilogueRelu : I32EnumAttrCase<"Relu", 2>;
def CublasLtMatmulEpilogueBiasRelu : I32EnumAttrCase<"BiasRelu", 3>;
def CublasLtMatmulEpilogueGelu : I32EnumAttrCase<"Gelu", 4>;
def CublasLtMatmulEpilogueBiasGelu : I32EnumAttrCase<"BiasGelu", 5>;
def CublasLtMatmulEpilogueGeluAux : I32EnumAttrCase<"GeluAux", 6>;
def CublasLtMatmulEpilogueBiasGeluAux : I32EnumAttrCase<"BiasGeluAux", 7>;


def CublasLtMatmulEpilogue: I32EnumAttr<"CublasLtMatmulEpilogue",
    "Epilogue for cublasLt matmul",
    [CublasLtMatmulEpilogueDefault, CublasLtMatmulEpilogueBias,
     CublasLtMatmulEpilogueRelu, CublasLtMatmulEpilogueBiasRelu,
     CublasLtMatmulEpilogueGelu, CublasLtMatmulEpilogueBiasGelu,
     CublasLtMatmulEpilogueGeluAux, CublasLtMatmulEpilogueBiasGeluAux]> {
  let genSpecializedAttr = 0;
  let cppNamespace = "::mlir::lmhlo_gpu";
}

def CublasLtMatmulEpilogueAttr : EnumAttr<LmhloGpuDialect, CublasLtMatmulEpilogue, "epilogue">;

def NormAlgorithmConfigAttr : AttrDef<
  LmhloGpuDialect, "NormAlgorithmConfig"> {
  let mnemonic = "norm_algorithm_config";
  let parameters = (ins
  "int64_t":$algorithm,
  "int64_t":$workspace_size
 );
  let assemblyFormat = "`<` struct(params) `>`";
 let summary = "GPU Norm Algorithm configuration";
}

def FusedMHAAlgorithmConfigAttr : AttrDef<
  LmhloGpuDialect, "FusedMHAAlgorithmConfig"> {
  let mnemonic = "fHMA_algorithm_config";
  let parameters = (ins
  "int64_t":$algorithm,
   // These 2 fields are a TableGen transliteration of AlgorithmProto.
   // Currently only knobs ids and values are relevant for fMHA but this
   // Attr can be used to add algorithm related fields.
   // The next two fields are aligned arrays of knob IDs and values to
   // represent the knob_id -> knob_value map.
   I64ArrayParameter:$knob_ids,
   I64ArrayParameter:$knob_values,
   "int64_t":$workspace_size
 );
  let assemblyFormat = "`<` struct(params) `>`";
 let summary = "GPU Fused Multi Headed Attention Algorithm configuration";
}

def FusedMhaDagDefault : I32EnumAttrCase<"Default", 0>;
def FusedMhaDagScaleBiasMaskSoftmax : I32EnumAttrCase<"ScaleBiasMaskSoftmax", 1>;
def FusedMhaDagScaleBiasMaskSoftmaxDropout : I32EnumAttrCase<"ScaleBiasMaskSoftmaxDropout", 2>;
def FusedMhaDagScaleMaskSoftmax : I32EnumAttrCase<"ScaleMaskSoftmax", 3>;
def FusedMhaDagScaleMaskSoftmaxDropout : I32EnumAttrCase<"ScaleMaskSoftmaxDropout", 4>;
def FusedMhaDagSoftmaxDropout : I32EnumAttrCase<"SoftmaxDropout", 5>;
def FusedMhaDagSoftmax : I32EnumAttrCase<"Softmax", 6>;
def FusedMhaDagScaleBiasSoftmaxDropout : I32EnumAttrCase<"ScaleBiasSoftmaxDropout", 7>;
def FusedMhaDagScaleBiasSoftmax : I32EnumAttrCase<"ScaleBiasSoftmax", 8>;

def FusedMhaBackwardDagScaleBiasSoftmaxDropout : I32EnumAttrCase<"BackwardScaleBiasSoftmaxDropout", 0>;
def FusedMhaBackwardDagScaleBiasSoftmax : I32EnumAttrCase<"BackwardScaleBiasSoftmax", 1>;
def FusedMhaBackwardDagScaleBiasMaskSoftmax : I32EnumAttrCase<"BackwardScaleBiasMaskSoftmax", 2>;
def FusedMhaBackwardDagScaleBiasMaskSoftmaxDropout : I32EnumAttrCase<"BackwardScaleBiasMaskSoftmaxDropout", 3>;
def FusedMhaBackwardDagSoftmax : I32EnumAttrCase<"BackwardSoftmax", 4>;
def FusedMhaBackwardDagSoftmaxDropout : I32EnumAttrCase<"BackwardSoftmaxDropout", 5>;

def FusedMhaDagSignature: I32EnumAttr<"FusedMhaDagSignature",
    "DAG configuration for Fused Multi-Headed Attention",
    [FusedMhaDagDefault, 
    FusedMhaDagScaleBiasMaskSoftmax, 
    FusedMhaDagScaleBiasMaskSoftmaxDropout, 
    FusedMhaDagScaleMaskSoftmax, 
    FusedMhaDagScaleMaskSoftmaxDropout, 
    FusedMhaDagSoftmaxDropout,
    FusedMhaDagSoftmax,
    FusedMhaDagScaleBiasSoftmaxDropout,
    FusedMhaDagScaleBiasSoftmax]> {
  let genSpecializedAttr = 0;
  let cppNamespace = "::mlir::lmhlo_gpu";
}

def FusedMhaBackwardDagSignature: I32EnumAttr<"FusedMhaBackwardDagSignature",
    "DAG configuration for Fused Multi-Headed Attention Backward",
    [
    FusedMhaBackwardDagScaleBiasSoftmaxDropout,
    FusedMhaBackwardDagScaleBiasSoftmax,
    FusedMhaBackwardDagScaleBiasMaskSoftmax,
    FusedMhaBackwardDagScaleBiasMaskSoftmaxDropout,
    FusedMhaBackwardDagSoftmax,
    FusedMhaBackwardDagSoftmaxDropout]> {
  let genSpecializedAttr = 0;
  let cppNamespace = "::mlir::lmhlo_gpu";
}

def FusedMhaDagSignatureAttr : EnumAttr<LmhloGpuDialect, FusedMhaDagSignature, "fused_mha_dag">;
def FusedMhaBackwardDagSignatureAttr : EnumAttr<LmhloGpuDialect, FusedMhaBackwardDagSignature, "fused_mha_backward_dag">;
#endif // LHLO_GPU_OPS_ENUMS
