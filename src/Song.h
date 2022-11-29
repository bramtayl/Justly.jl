#pragma once

#include <QAbstractItemModel>

#include "TreeNode.h"
#include "DefaultInstrument.h"

const int DEFAULT_FREQUENCY = 220;
const int DEFAULT_VOLUME_PERCENT = 50;
const int DEFAULT_TEMPO = 200;

const int NOTE_CHORD_COLUMNS = 9;

class Song : public QAbstractItemModel {
  Q_OBJECT

 public:
  int frequency = DEFAULT_FREQUENCY;
  int volume_percent = DEFAULT_VOLUME_PERCENT;
  int tempo = DEFAULT_TEMPO;
  
  // pointer so the pointer, but not object, can be constant
  const std::unique_ptr<TreeNode> root_pointer = std::make_unique<TreeNode>();

  explicit Song(QObject *parent = nullptr);
  void load(const QJsonObject &json_object);

  [[nodiscard]] auto node_from_index(const QModelIndex &index) const
      -> TreeNode &;
  [[nodiscard]] auto data(const QModelIndex &index, int role) const
      -> QVariant override;
  [[nodiscard]] auto flags(const QModelIndex &index) const
      -> Qt::ItemFlags override;
  [[nodiscard]] auto headerData(int section, Qt::Orientation orientation,
                                int role = Qt::DisplayRole) const
      -> QVariant override;
  [[nodiscard]] auto index(int row, int column,
                           const QModelIndex &parent = QModelIndex()) const
      -> QModelIndex override;
  [[nodiscard]] auto parent(const QModelIndex &index) const
      -> QModelIndex override;
  [[nodiscard]] auto rowCount(const QModelIndex &parent = QModelIndex()) const
      -> int override;
  [[nodiscard]] auto columnCount(
      const QModelIndex &parent = QModelIndex()) const -> int override;
  auto setData_directly(const QModelIndex &index, const QVariant &value,
                        int role) -> bool;
  auto insertRows(int position, int rows,
                  const QModelIndex &index = QModelIndex()) -> bool override;
  auto insert_children(int position,
                       std::vector<std::unique_ptr<TreeNode>> &insertion,
                       const QModelIndex &parent_index) -> void;
  auto removeRows(int position, int rows,
                  const QModelIndex &index = QModelIndex()) -> bool override;
  auto remove_save(int position, size_t rows, const QModelIndex &parent_index,
                   std::vector<std::unique_ptr<TreeNode>> &deleted_rows)
      -> void;
  auto copy(const QModelIndex &first_index, size_t rows,
            std::vector<std::unique_ptr<TreeNode>> &copied) const -> void;
  auto setFrequency(int value, bool send_signal = true) -> void;
  auto setVolumePercent(int value, bool send_signal = true) -> void;
  auto setTempo(int value, bool send_signal = true) -> void;
  void save(QJsonObject &json_object) const;
  auto setData(const QModelIndex &index, const QVariant &value, int role)
      -> bool override;

 signals:
  void frequency_changed(int new_value);
  void volume_changed(int new_value);
  void tempo_changed(int new_value);
  void set_data_signal(const QModelIndex &index, const QVariant &value,
                       int role);
};
